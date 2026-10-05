extends "res://Scripts/entity.gd" # Herda as propriedades básicas de uma entidade (como vida)

# ==========================================================
# CONFIGURAÇÕES DE MOVIMENTAÇÃO E FORÇA DO INIMIGO
# ==========================================================
@export var SPEED = 30           # Velocidade padrão de caminhada horizontal
@export var JUMP_FORCE = -350.0  # Força vertical aplicada ao pular
@export var extra_x_speed = 0    # Velocidade horizontal extra durante saltos (não utilizada atualmente)

# Variables de controle de física e componentes básicos
var direction = 1                # Direção atual do movimento: 1 para Direita, -1 para Esquerda
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity") # Puxa o valor da gravidade do projeto

# Componentes visuais, hitboxes e timers anexados ao Nó do Inimigo
@onready var purple_mushroom: AnimatedSprite2D = $AnimatedSprite2D # Gerencia as animações do cogumelo
@onready var hitbox = $Area2D                                     # Detecta colisões com projéteis/jogador
@onready var delay_after_jump_timer = $DelayAfterJumpTimer        # Timer para atraso após pulo (não utilizado)

# Sensores físicos (RayCasts) para mapear o ambiente ao redor do inimigo
@onready var floor_check_right = $RayCast2DDownRight # Sensor diagonal inferior direito (busca por buracos/limite do chão)
@onready var floor_check_left = $RayCast2DDownLeft   # Sensor diagonal inferior esquerdo (busca por buracos/limite do chão)
@onready var wall_check = $WallCheck                 # Sensor horizontal frontal para detectar paredes/obstáculos

# ==========================================================
# VARIÁVEIS DE CONTROLE DA INTELIGÊNCIA ARTIFICIAL (IA)
# ==========================================================
var change_direction_timer = 0.0     # Acumulador de tempo para andar em uma direção antes de virar sozinho
var time_to_change = 0.0             # Tempo alvo sorteado para mudar de rumo de forma voluntária
var jump_timer = 0.0                 # Acumulador de tempo para tentar um pulo aleatório
var time_to_jump = 0.0               # Tempo alvo sorteado para o inimigo decidir saltar

# Máquinas de estado e flags para gerenciar travamentos e fuga
var is_climbing = false              # Registra se o inimigo está escalando algo (não implementado)
var wall_sensor_cooldown = false     # Cooldown para evitar ler colisão na parede repetidamente
var bump_counter = 0                 # Conta quantas vezes o inimigo bateu seguidamente no mesmo lugar
var last_bump_position = Vector2.ZERO # Salva a última posição onde o inimigo ficou travado
var is_escaping = false              # Se true, ativa o comportamento de super-pulo de fuga (desengatar de cantos)
var escape_jump_multiplier = 1.0     # Multiplicador para aumentar a altura do pulo de fuga

# Estados básicos de movimentação
var is_jumping = false               # Flag se está no ar
var is_jumping_boost = false         # Flag para pulo fortificado (não utilizada)
var can_change_direction = true      # Permissão para virar de lado

func _ready() -> void:
	jump_frames_animation()          # Ajusta a velocidade da animação do pulo com base na física
	hitbox.body_entered.connect(_on_body_entered) # Conecta o sinal de colisão com projéteis
	direction = [-1, 1].pick_random() # Sorteia se o inimigo começa andando para a esquerda ou direita
	#_set_random_jump()               # Sorteia os intervalos de tempo para o primeiro pulo voluntário
	#_set_random_timer()              # Sorteia os intervalos de tempo para mudar de rumo voluntariamente
	update_sensors()                 # Alinha os sensores físicos para o lado correto em que começou olhando

# Ajusta a velocidade (FPS) da animação "Jump" para casar perfeitamente com o tempo em segundos que o corpo passa no ar
func jump_frames_animation():
	var jump_duration = (2 * abs(JUMP_FORCE)) / gravity # Calcula matematicamente o tempo total de subida e descida
	var frame_count = purple_mushroom.sprite_frames.get_frame_count("Jump") # Pega quantos desenhos compõem a animação
	var ideal_fps = frame_count / jump_duration # Define a taxa ideal de frames por segundo
	purple_mushroom.sprite_frames.set_animation_speed("Jump", ideal_fps) # Aplica essa velocidade diretamente no Sprite

# Sorteia um tempo aleatório entre 8 e 12 segundos para o inimigo virar de lado sozinho enquanto vaga
func _set_random_timer() -> void:
	time_to_change = randf_range(8.0, 12.0)
	change_direction_timer = 0.0

# Sorteia temporizadores para pulo livre. O jump_timer negativo garante um intervalo inicial de calmaria
func _set_random_jump() -> void:
	time_to_jump = randf_range(1.0, 3.0)
	jump_timer = randf_range(-4.0, -2.0)

# Loop principal de execução física
func _physics_process(delta: float) -> void:
	# --- ESTADO NO AR (CAINDO OU PULANDO) ---
	if not is_on_floor():
		is_jumping = true
		velocity.y += gravity * delta # Aplica a gravidade continuamente para empurrar o corpo para baixo
		
		# Define a velocidade no ar dependendo se ele está fugindo de um travamento ou apenas pulando normal
		if is_escaping:
			velocity.x = 250 * direction
		else:
			velocity.x = SPEED * direction
	
	# --- ESTADO TOCANDO O CHÃO ---
	else:
		is_jumping = false
		
		# Se estiver executando uma manobra de fuga no chão, corre rápido
		if is_escaping:
			velocity.x = 250 * direction
		else:
			# Checa se há um buraco iminente à direita ou à esquerda
			var hole_right = not floor_check_right.is_colliding()
			var hole_left = not floor_check_left.is_colliding()
			
			# LÓGICA DE DETECÇÃO DE BORDAS:
			if hole_right and hole_left:
				# Se não há chão em nenhum dos dois sensores diagonais, ele está preso em uma única plataforma isolada de 1 bloco
				_force_escape_jump() # Força um pulo de emergência com velocidade alterada
			elif hole_right and direction == 1:
				# Indo para a direita e encontrou o fim do bloco: para o movimento e vira para a esquerda
				velocity.x = 0
				_flip_direction(direction * -1)
			elif hole_left and direction == -1:
				# Indo para la esquerda e encontrou o fim do bloco: para o movimento e vira para a direita
				velocity.x = 0
				_flip_direction(direction * -1)
			else:
				# Chão totalmente plano e seguro à frente, avança normalmente na velocidade padrão
				velocity.x = SPEED * direction
			
	# --- GERENCIAMENTO DE TIMERS DA IA (SÓ FUNCIONA FORA DO MODO DE FUGA) ---
	if not is_escaping:
		# Acumula tempo e vira de lado sozinho se andar tempo demais em linha reta
		change_direction_timer += delta
		if change_direction_timer >= time_to_change:
			_flip_direction(direction * -1)
			
		# Acumula tempo e testa se pode pular de forma semi-aleatória (somente se estiver no solo)
		#jump_timer += delta
		#if jump_timer >= time_to_jump and is_on_floor():
			#_handle_random_jump_ia()
			
	# --- MÁQUINA DE ANIMAÇÃO VISUAL ---
	if is_jumping:
		purple_mushroom.play("Jump")
	else:
		purple_mushroom.play("Move")
		
	move_and_slide() # Executa a movimentação com o motor de física do Godot

	# --- RECUPERAÇÃO DE TRAVAMENTO EM PAREDES ---
	if is_on_wall() and is_on_floor():
		#print("COLIDIU NA PAREDE E ESTA NO CHAO")
		# Se colidiu horizontalmente de frente e o sensor frontal confirmar parede, executa rotina de destravamento
		if wall_check.enabled and wall_check.is_colliding():
			#unstuck_from_buping_walls()
			_flip_direction(direction * -1)
		
	# Inverte o lado visual do sprite de acordo com o vetor de velocidade atual
	if velocity.x < 0:
		purple_mushroom.flip_h = true
	elif velocity.x > 0:
		purple_mushroom.flip_h = false
		
	# Se cair em um abismo sem fim abaixo da coordenada Y 1500, deleta o inimigo da memória para evitar lag
	if global_position.y > 1500:
		queue_free()

# Executa uma checagem via física ("Raycast invisível programático") para simular que o inimigo olha se vale a pena pular
func _handle_random_jump_ia() -> void:
	var jump_dist = 40 # Distância à frente onde o inimigo simula o ponto de aterrissagem
	
	var space_state = get_world_2d().direct_space_state
	# Cria uma linha invisível para baixo à frente do inimigo para testar se há piso firme ali antes de saltar
	var query = PhysicsRayQueryParameters2D.create(
		global_position + Vector2(jump_dist * direction, 0),
		global_position + Vector2(jump_dist * direction, 50),
	)
	query.exclude = [self.get_rid()] # Exclui a si mesmo da verificação para não ler o próprio corpo
	
	var result = space_state.intersect_ray(query)
	if result:
		# Se houver chão seguro do outro lado do espaço amostrado, o inimigo executa o pulo
		velocity.y = JUMP_FORCE
		velocity.x = SPEED * direction
		is_jumping = true
		_set_random_jump() # Sorteia um novo tempo para o próximo pulo
	else:
		# Se for cair em um buraco se pulasse, cancela o pulo, vira de costas e redefine o timer
		_flip_direction(direction * -1)
		_set_random_jump()

# Comando de emergência acionado quando o inimigo cai ou fica encurralado em 1 tile
func _force_escape_jump() -> void:
	is_escaping = true
	direction = [-1, 1].pick_random() # escolhe uma direção aleatória para tentar a sorte e sair do buraco
	update_sensors()
	
	# Aplica uma força vertical massiva (40% maior) e arremessa o inimigo para o lado na força máxima
	velocity.y = JUMP_FORCE * (escape_jump_multiplier + 0.4)
	velocity.x = 250 * direction
	is_jumping = true
	# Mantém a flag de escape ativa por meio segundo, depois desliga para ele voltar a andar devagar
	get_tree().create_timer(0.5).timeout.connect(func(): is_escaping = false)

# Rotina disparada para evitar que o inimigo fique oscilando infinitamente preso em quinas de blocos (Inativa no momento)
func unstuck_from_buping_edges(hole_left, hole_right) -> void:
	# Verifica se ele está batendo na mesma coordenada geográfica repetidamente (raio de 30 pixels)
	if global_position.distance_to(last_bump_position) < 30:
		bump_counter += 1
	else:
		bump_counter = 1
		last_bump_position = global_position
		
	# Se acumular 3 colisões na quina, força um pulo alto para tentar saltar por cima do obstáculo
	if bump_counter > 3:
		velocity.y = JUMP_FORCE - 50
		velocity.x = (SPEED + 50) * direction
		is_jumping = true
		bump_counter = 0
		get_tree().create_timer(0.5).timeout.connect(func(): 
			if is_instance_valid(self):
				set_physics_process(true))
	elif wall_check.is_colliding():
		# Se houver parede bloqueando, inverte a direção, desliga o sensor frontal por 1 segundo para evitar falsos positivos
		direction *= -1
		update_sensors()
		velocity.x = SPEED * direction
		wall_check.enabled = false
		get_tree().create_timer(1.0).timeout.connect(func():
			if is_instance_valid(wall_check):
				wall_check.enabled = true)
	else:
		# Comportamento padrão de segurança: apenas inverte o lado do movimento
		_flip_direction(direction * -1)
		bump_counter = 0

# Congela temporariamente a física do inimigo (Útil para simular atordoamento ou efeitos especiais)
func _apply_physics_freeze(time: float) -> void:
	set_physics_process(false)
	get_tree().create_timer(time).timeout.connect(func(): 
		if is_instance_valid(self): 
			set_physics_process(true))

# Rotina executada para tirar o inimigo de loops infinitos andando contra paredes ou cantos de tela
func unstuck_from_buping_walls() -> void:
	if global_position.distance_to(last_bump_position) > 30:
		bump_counter += 1
	else:
		bump_counter = 1
		last_bump_position = global_position
		
	# Se o inimigo insistir na parede seguidamente por 2 ou mais vezes, executa uma investida vertical potente de fuga
	if bump_counter >= 2:
		velocity.y = JUMP_FORCE * (escape_jump_multiplier + 0.6) # Pulo muito alto
		velocity.x = (SPEED + 200) * direction                   # Impulso horizontal muito rápido
		is_jumping = true
		bump_counter = 0
		set_physics_process(false) # Pausa temporariamente o processo nativo para priorizar o vetor de impulso
		# Desliga temporariamente a colisão do sensor e religa após meio segundo
		get_tree().create_timer(0.5).timeout.connect(func(): if is_instance_valid(wall_check): wall_check.enabled = true)
		_flip_direction(direction * -1) # Inverte a direção de busca
		set_physics_process(true)      # Reativa o processamento
	elif wall_check.is_colliding():
		# Se bater de leve em parede, faz um pequeno pulo com força randômica e velocidade horizontal alta (250)
		velocity.y = JUMP_FORCE * randf_range(0.8, 1.2)
		velocity.x = (250) * direction
		wall_check.enabled = false
		get_tree().create_timer(0.5).timeout.connect(func(): if is_instance_valid(wall_check): wall_check.enabled = true)
	else:
		# Fallback simples: vira para trás e zera o marcador de colisões
		_flip_direction(direction * -1)
		bump_counter = 0
		
# Sincroniza a orientação geométrica do sensor frontal de parede de acordo com o lado que ele está andando (Inverte a escala X)
func update_sensors() -> void:
	wall_check.target_position.x = abs(wall_check.target_position.x) * direction
	purple_mushroom.flip_h = (direction == -1)

# Avalia analiticamente qual direção é segura para saltar com base nas leituras dos sensores inferiores (Não usada)
func _get_safe_jump_direction() -> int:
	var right_safe = floor_check_right.is_colliding()
	var left_safe = floor_check_left.is_colliding()
	
	if right_safe:
		return 1
	if left_safe:
		return -1
	else:
		return 0

# Chama o comportamento visual herdado da classe base ("entity.gd") para piscar o sprite em vermelho ao tomar dano

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("slash"):
		print("Slash entrou")
		take_damage(2)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("bullet"):
		print("bullet entrou")
		body.queue_free() 
		take_damage(1)  

func _on_death() -> void:
	queue_free()

# Altera a variável de direção de movimentação e protege o inimigo de cometer "suicídio" andando em buracos visíveis
func _flip_direction(new_dir: int) -> void:
	if new_dir == 1:
		# Se tentar virar para a direita, mas o sensor de buraco acusar vazio, força ele a continuar indo para a esquerda
		if not floor_check_right.is_colliding():
			new_dir = -1
	elif new_dir == -1:
		# Se tentar virar para a esquerda, mas o sensor de buraco acusar vazio, força ele a continuar indo para a direita
		if not floor_check_left.is_colliding():
			new_dir = 1
			
	direction = new_dir      # Aplica a nova direção validada
	update_sensors()         # Sincroniza a orientação dos sensores e sprites
	_set_random_timer()      # Sorteia um novo tempo aleatório de caminhada estável
