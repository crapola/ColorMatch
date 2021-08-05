# Class name -------------------------------------------------------------------
# Extends ----------------------------------------------------------------------
extends Particles2D
# Docstring --------------------------------------------------------------------
# Signals ----------------------------------------------------------------------
# Enums ------------------------------------------------------------------------
# Constants --------------------------------------------------------------------
# Exported variables -----------------------------------------------------------
# Public variables -------------------------------------------------------------
# Private variables ------------------------------------------------------------
# Onready variables ------------------------------------------------------------
# Built-in virtual methods -----------------------------------------------------
func _init():
	process_material=process_material.duplicate()
	process_material.color_ramp=process_material.color_ramp.duplicate()
	process_material.color_ramp.gradient=process_material.color_ramp.gradient.duplicate()
func _ready():
	emitting=true
	$timer.wait_time=lifetime/speed_scale
	$timer.start()
# Public methods ---------------------------------------------------------------
func set_color(c):
	process_material.color_ramp.gradient.set_color(0,c)
	process_material.color_ramp.gradient.set_color(1,c*Color(1,1,1,0))
# Private methods --------------------------------------------------------------
func _on_timer_timeout():
	queue_free()
