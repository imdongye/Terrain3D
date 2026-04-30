class_name PhyBall extends RefCounted

const radius: float = 0.021 # m
const mass: float = 0.046 # kg
const inv_mass: float = 1.0/mass
const inertia: float = 8.35*10e-6
const gravity_acc: Vector3 = Vector3.DOWN*9.8

var env_temperature: float = 20.0 # celsius
var env_altitude: float = 10.0 # m
var env_jumidity: float = 30.0

var dimple_factor: float = 1.0

var blps: PackedVector3Array
var idx_apex: int = 0
var idx_landing: int = 0

var l_drag_scale: float
var lift_scale: float

var l_vel: Vector3
var a_vel: Vector3
var pos: Vector3

func reset() -> void:
	blps.clear()

func integrate_step(dt: float) -> void:
	



const l_drag_scale_lut: PackedFloat32Array = [
	# C0(Low Spin) -----------------------------------> C10(High Spin, 9550rpm+)
	0.55, 0.58, 0.61, 0.64, 0.67, 0.70, 0.72, 0.73, 0.74, 0.75, 0.75, # R0: 0~10m/s (Chip)
	0.60, 0.63, 0.66, 0.69, 0.72, 0.75, 0.77, 0.78, 0.79, 0.80, 0.80, # R1: 10~20m/s (Chip)
	0.75, 0.77, 0.79, 0.82, 0.85, 0.88, 0.90, 0.92, 0.93, 0.94, 0.94, # R2: 20~30m/s (Slow Iron)
	0.88, 0.90, 0.92, 0.94, 0.96, 0.98, 1.00, 1.01, 1.02, 1.02, 1.02, # R3: 30~40m/s (Mid Iron)
	0.96, 0.98, 1.00, 1.03, 1.05, 1.07, 1.09, 1.10, 1.11, 1.11, 1.11, # R4: 40~50m/s (Fast Iron)
	0.98, 1.00, 1.02, 1.04, 1.06, 1.07, 1.08, 1.09, 1.09, 1.10, 1.10, # R5: 50~60m/s (Driver/Wedge)
	1.00, 1.02, 1.04, 1.05, 1.07, 1.08, 1.09, 1.10, 1.11, 1.12, 1.12, # R6: 60~70m/s (Fast Driver)
	1.02, 1.03, 1.05, 1.06, 1.08, 1.09, 1.10, 1.11, 1.12, 1.13, 1.13, # R7: 70~80m/s
	1.03, 1.04, 1.06, 1.07, 1.09, 1.10, 1.11, 1.12, 1.13, 1.14, 1.14, # R8: 80~90m/s
	1.04, 1.05, 1.07, 1.08, 1.10, 1.11, 1.12, 1.13, 1.14, 1.15, 1.15, # R9: 90~100m/s
	1.05, 1.06, 1.08, 1.09, 1.11, 1.12, 1.13, 1.14, 1.15, 1.15, 1.15  # R10: 100m/s+
]
const lift_scale_lut: PackedFloat32Array = [
	# C0(Low Spin) -----------------------------------> C10(High Spin, 9550rpm+)
	2.21, 2.23, 2.25, 2.29, 2.31, 2.33, 2.36, 2.38, 2.40, 2.40, 2.40, # R0: 0~10m/s (Chip)
	2.15, 2.17, 2.19, 2.23, 2.25, 2.27, 2.31, 2.33, 2.35, 2.35, 2.35, # R1: 10~20m/s (Chip)
	2.00, 2.02, 2.04, 2.08, 2.10, 2.12, 2.15, 2.17, 2.19, 2.19, 2.19, # R2: 20~30m/s (Slow Iron)
	1.94, 1.96, 1.96, 1.98, 2.00, 2.00, 2.02, 2.02, 2.04, 2.04, 2.04, # R3: 30~40m/s (Mid Iron)
	1.98, 1.96, 1.94, 1.92, 1.90, 1.88, 1.85, 1.83, 1.81, 1.81, 1.81, # R4: 40~50m/s (Fast Iron)
	1.96, 1.94, 1.92, 1.90, 1.88, 1.86, 1.85, 1.83, 1.81, 1.81, 1.81, # R5: 50~60m/s (Driver/Wedge)
	1.92, 1.90, 1.88, 1.86, 1.85, 1.83, 1.81, 1.79, 1.77, 1.77, 1.77, # R6: 60~70m/s (Fast Driver)
	1.88, 1.86, 1.85, 1.83, 1.81, 1.79, 1.77, 1.75, 1.73, 1.73, 1.73, # R7: 70~80m/s
	1.85, 1.83, 1.81, 1.79, 1.77, 1.75, 1.73, 1.71, 1.69, 1.69, 1.69, # R8: 80~90m/s
	1.81, 1.79, 1.77, 1.75, 1.73, 1.71, 1.69, 1.67, 1.65, 1.65, 1.65, # R9: 90~100m/s
	1.81, 1.79, 1.77, 1.75, 1.73, 1.71, 1.69, 1.67, 1.65, 1.65, 1.65  # R10: 100m/s+
]
func update_l_drag_and_lift_scale() -> void:
	var row: int = min(int(l_vel.length()/10.0), 10) # 0~10(100 m/s)
	var col: int = min(int(a_vel.length()/100.0), 10) # 0~10(9549rpm)
	var idx: int = row*11 + col
	l_drag_scale = l_drag_scale_lut[idx]
	lift_scale = lift_scale_lut[idx]
