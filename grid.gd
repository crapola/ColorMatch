tool
# Class name -------------------------------------------------------------------
# Extends ----------------------------------------------------------------------
extends Node2D
# Docstring --------------------------------------------------------------------
# Signals ----------------------------------------------------------------------
# Enums ------------------------------------------------------------------------
# Constants --------------------------------------------------------------------
const TILE=preload("tile.tscn")
const EXPLOSION=preload("explosion.tscn")
# Exported variables -----------------------------------------------------------
export(int,0,64) var width=10
export(int,0,64) var height=10
# Public variables -------------------------------------------------------------
# Private variables ------------------------------------------------------------
var _colors=preload("res://colors.tres")
var _tiles_root
# Onready variables ------------------------------------------------------------
# Built-in virtual methods -----------------------------------------------------
func _ready():
	if Engine.is_editor_hint():
		return
	reset()
	
func _draw():
	draw_rect(Rect2(0,0,width*32,height*32),Color.red,false)
# Public methods ---------------------------------------------------------------
func index(x,y)->int:
	return int(x)%width+int(y)*width

func reset():
	_create_root()
	_fill()

func swap(tile1,tile2):
	print("Swapping ",tile1," and ",tile2)
	# Swap real positions right away.
	var p=tile1.position
	tile1.position=tile2.position
	tile2.position=p
	# Adjust visuals so it appears smooth.
	tile1._tween.stop(tile1._mover,"position")
	tile2._tween.stop(tile2._mover,"position")
	tile1._mover.position=tile2.position-tile1.position+tile1._mover.position
	tile2._mover.position=tile1.position-tile2.position+tile2._mover.position
	tile1.swap_out()
	tile2.swap_out()
	# Swap nodes in scene tree.
	var i1=_tiles().find(tile1)
	var i2=_tiles().find(tile2)
	_tiles_root.move_child(tile1,i2)
	_tiles_root.move_child(tile2,i1)
# Private methods --------------------------------------------------------------
func _contiguous_tiles_of_same_color(tile)->Array:
	var stack=[tile]
	var visited_set=[]
	while !stack.empty():
		var current=stack[0]
		stack.pop_front()
		var next=_neighbors_same_color(current)
		for n in next:
			if !visited_set.has(n):
				visited_set.append(n)
				stack.append(n)
	print(visited_set)
	return visited_set

func _create_root():
	if _tiles_root:
		_tiles_root.free()
	_tiles_root=Node2D.new()
	_tiles_root.name="tiles"
	add_child(_tiles_root)

func _drop_columns():
	for x in range(width):
		var empty_count:int=0
		for y in range(height-1,-1,-1):
			var tile_here=_tile_at(x,y)
			if not tile_here.visible:
				empty_count+=1
			else:
				if empty_count>0:
					swap(tile_here,_tile_at(x,y+empty_count))

func _fill():
	randomize()
	var kernels=[
	[[0,1],[2,3]],
	[[3,4],[5,0]]
	]
	for y in range(height):
		for x in range(width):
			var t=TILE.instance()
			_tiles_root.add_child(t)
			t.position.x=x*t.size
			t.position.y=y*t.size
			var c=_colors.colors.values()
			var r=kernels[randi()%2][y%2][x%2]
			#r=randi()%5
			t.color=c[r]
			t.set_name("T"+str(x)+"_"+str(y)+"_"+_colors.colors.keys()[r])
			t.connect("swap",self,"_on_swap")

func _find_row_or_column(tile_array)->bool:
	if tile_array.size()<3:
		return false
	tile_array.sort_custom(self,"_tiles_compare_indices_row_major")
	var tile_array_col:Array=tile_array.duplicate()
	tile_array_col.sort_custom(self,"_tiles_compare_indices_col_major")
	for i in range(tile_array.size()+1-3):
		var r1=_tile_grid_position(tile_array[i]).x
		var r2=_tile_grid_position(tile_array[i+1]).x
		var r3=_tile_grid_position(tile_array[i+2]).x
		var c1=_tile_grid_position(tile_array_col[i]).y
		var c2=_tile_grid_position(tile_array_col[i+1]).y
		var c3=_tile_grid_position(tile_array_col[i+2]).y
		if r3==r2+1 and r2==r1+1:
			print("Row found.")
			return true
		if c3==c2+1 and c2==c1+1:
			print("Column found.")
			return true
	return false

func _neighbors_same_color(tile)->Array:
	var t=_tiles()
	var p=_tile_grid_position(tile)
	var x=p.x
	var y=p.y
	var up=_tile_at(x,y-1)
	var down=_tile_at(x,y+1)
	var left=_tile_at(x-1,y)
	var right=_tile_at(x+1,y)
	var a=[]
	if up and _tiles_same_color(tile,up):
		a.append(up)
	if down and _tiles_same_color(tile,down):
		a.append(down)
	if left and _tiles_same_color(tile,left):
		a.append(left)
	if right and _tiles_same_color(tile,right):
		a.append(right)
	return a

func _on_swap(tile1,tile2):
	swap(tile1,tile2)
	_validate_move(tile1,tile2)

func _tile_at(x,y):
	var t=_tiles()
	if x<0 or x>=width or y<0 or y>=height:
		return null
	return t[index(x,y)]

func _tile_new(x,y):
	var t=TILE.instance()
	add_child(t)
	move_child(t,index(x,y))

func _tile_grid_position(tile):
	var i:int=tile.get_index()
	return Vector2(i%width,i/width)

func _tiles():
	return _tiles_root.get_children()

func _tiles_compare_indices_row_major(tile1,tile2):
	return tile1.get_index()<tile2.get_index()

func _tiles_compare_indices_col_major(tile1,tile2):
	var i1=tile1.get_index()
	var i2=tile2.get_index()
	var ic1=int(i1/width)+(i1%width)*width
	var ic2=int(i2/width)+(i2%width)*width
	return ic1<ic2

func _tiles_destroy(tiles:Array):
	for t in tiles:
		var e=EXPLOSION.instance()
		e.set_color(t.color)
		e.position=t.position+Vector2(16,16)
		add_child(e)
		t.visible=false
		t.color=Color.black

func _tiles_same_color(t1,t2)->bool:
	return t1.color==t2.color

func _validate_move(tile1,tile2):
	# tile1 and tile2 have just been swapped.
	if tile1.visible:
		var m1=_contiguous_tiles_of_same_color(tile1)
		if _find_row_or_column(m1):
			_tiles_destroy(m1)
	if tile2.visible:
		var m2=_contiguous_tiles_of_same_color(tile2)
		if _find_row_or_column(m2):
			_tiles_destroy(m2)
	_drop_columns()

