# Class name -------------------------------------------------------------------
# Extends ----------------------------------------------------------------------
extends Node2D
# Docstring --------------------------------------------------------------------
# Signals ----------------------------------------------------------------------
signal swap(tile1,tile2)
# Enums ------------------------------------------------------------------------
# Constants --------------------------------------------------------------------
# Exported variables -----------------------------------------------------------
# Public variables -------------------------------------------------------------
var color:Color setget color_set,color_get
var size:int setget ,size_get
# Private variables ------------------------------------------------------------
var _colors=preload("res://colors.tres")
var _grabbed=false
var _swapping=null
# Onready variables ------------------------------------------------------------
onready var _rectangle=$mover/clickable/visual/rectangle
onready var _animations=$animations
onready var _tween=$tween
onready var _mover=$mover
onready var _area=$area_static
# Built-in virtual methods -----------------------------------------------------
func _input(event):
	if _grabbed:
		if event is InputEventMouseMotion:
			_mover.position += event.relative
		if event is InputEventMouseButton and not event.pressed:
			_grabbed=false
			_tween.interpolate_property(_mover,"position",_mover.position,Vector2.ZERO,4.0,Tween.TRANS_ELASTIC,Tween.EASE_OUT)
			_tween.start()
			z_index=1
			_animations.play_backwards("grab")
			if _swapping:
				print("Swap with ",_swapping)
				emit_signal("swap",self,_swapping)
func _to_string():
	return name
# Public methods ---------------------------------------------------------------
func color_set(x):
	_rectangle.color=x
func color_get():
	return _rectangle.color
func size_get():
	return _rectangle.rect_size.x
func swap_in(other):
	_tween.interpolate_property(_mover,"position",Vector2.ZERO,other.position-position,1.0,Tween.TRANS_CUBIC,Tween.EASE_OUT)
	_tween.start()
	z_index=1
func swap_out():
	_tween.interpolate_property(_mover,"position",_mover.position,Vector2.ZERO,1.0,Tween.TRANS_CUBIC,Tween.EASE_OUT)
	_tween.start()
	z_index=1
# Private methods --------------------------------------------------------------
func _on_Control_gui_input(event:InputEvent):
	if !_grabbed:
		if event is InputEventMouseButton:
			if event.button_index == BUTTON_LEFT and event.pressed:
				print(self," clicked.")
				_tween.stop(_mover,"position")
				_grabbed=true
				z_index=2
				_animations.play("grab")
#	if event.is_action("ui_accept"):
#		print("!!")
func _on_tween_tween_completed(object, key):
	if object==_mover and key==":position":
		_grabbed=false
		z_index=0
func _on_area_area_entered(area):
	var other=area.get_parent()
	if other==self or other==_swapping:
		return
	if _grabbed:
		if _swapping:
			_swapping.swap_out()
		_swapping=other
		_swapping.swap_in(self)
func _on_area_area_exited(area):
	var other=area.get_parent()
	if other==_swapping:
		_swapping.swap_out()
		_swapping=null
