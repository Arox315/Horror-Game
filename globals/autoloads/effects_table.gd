extends Node

enum Effects {
	ACCELERATING_MOVE_SPEED,
	BONUS_JUMP_HEIGHT,
	TEST01
}

const TABLE: Dictionary = {
	Effects.ACCELERATING_MOVE_SPEED: preload("uid://dga6hld40vbyn"),
	Effects.BONUS_JUMP_HEIGHT: preload("uid://bwtwbvcujr4d8"),
	Effects.TEST01: preload("uid://dgjqlisdvkwyi")
}
