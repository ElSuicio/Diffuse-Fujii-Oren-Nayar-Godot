@tool
extends VisualShaderNodeCustom
class_name VisualShaderNodeDiffuseFujiiOrenNayarApproximation

# CC0 1.0 Universal, ElSuicio, 2026.
# GODOT v4.6.2.stable.
# x.com/ElSuicio
# github.com/ElSuicio
# Contact email [interdreamsoft@gmail.com]

func _get_name() -> String:
	return "FujiiOrenNayarApproximation"

func _get_category() -> String:
	return "Lightning/Diffuse"

func _get_description() -> String:
	return "Fujii approximation to Full Oren-Nayar Diffuse Reflectance Model."

func _get_return_icon_type() -> PortType:
	return VisualShaderNode.PORT_TYPE_VECTOR_3D

func _is_available(mode : Shader.Mode, type : VisualShader.Type) -> bool:
	if( mode == Shader.MODE_SPATIAL and type == VisualShader.TYPE_LIGHT ):
		return true
	else:
		return false

#region Input
func _get_input_port_count() -> int:
	return 7

func _get_input_port_name(port : int) -> String:
	match port:
		0:
			return "Normal"
		1:
			return "Light"
		2:
			return "View"
		3:
			return "Light Color"
		4:
			return "Attenuation"
		5:
			return "Diffuse Color"
		6:
			return "sigma"
	
	return ""

func _get_input_port_type(port : int) -> PortType:
	match port:
		0:
			return PORT_TYPE_VECTOR_3D # Normal.
		1:
			return PORT_TYPE_VECTOR_3D # Light.
		2:
			return PORT_TYPE_VECTOR_3D # View.
		3:
			return PORT_TYPE_VECTOR_3D # Light Color.
		4:
			return PORT_TYPE_SCALAR # Attenuation.
		5:
			return PORT_TYPE_VECTOR_3D # Diffuse Color.
		6:
			return PORT_TYPE_SCALAR # Sigma.
	
	return PORT_TYPE_SCALAR

func _get_input_port_default_value(port : int) -> Variant:
	match port:
		6:
			return 30.0 # Sigma.
	
	return

#endregion

#region Output
func _get_output_port_count() -> int:
	return 1

func _get_output_port_name(_port : int) -> String:
	return "Diffuse"

func _get_output_port_type(_port : int) -> PortType:
	return PORT_TYPE_VECTOR_3D

#endregion

func _get_code(input_vars : Array[String], output_vars : Array[String], _mode : Shader.Mode, _type : VisualShader.Type) -> String:
	var default_vars : Array[String] = [
		"NORMAL",
		"LIGHT",
		"VIEW",
		"LIGHT_COLOR",
		"ATTENUATION",
		"ALBEDO"
		]
	
	for i in range(0, input_vars.size(), 1):
		if(!input_vars[i]):
			input_vars[i] = default_vars[i]
	
	var shader : String = """
	const float INV_PI = 0.31830988618379067154;
	
	vec3 n = normalize( {normal} );
	vec3 l = normalize( {light} );
	vec3 v = normalize( {view} );
	
	float NdotL = dot(n, l); // cos(theta_l) == cos(theta_i).
	
	if (NdotL >= 0.0) {
		float NdotV = min(max(dot(n, v), 1e-3), 1.0); // cos(theta_v) == cos(theta_r).
		
		// https://mimosa-pudica.net/improved-oren-nayar.html
		float sigma2 = pow({sigma} * PI / 180.0, 2.0);
		
		float t = dot(l, v) - NdotL * NdotV;
		
		if (t > 0.0) {
			t /= max(NdotL, NdotV);
		}
		
		vec3 A = (1.0 - 0.5 * (sigma2 / (sigma2 + 0.33)) + 0.17 * {diffuse_color} * (sigma2 / (sigma2 + 0.13)));
		vec3 B = vec3(0.45 * (sigma2 / (sigma2 + 0.09)));
		
		vec3 diffuse_fujii_oren_nayar = INV_PI * (A + B * t) * NdotL;
		
		{output} = {light_color} * {attenuation} * diffuse_fujii_oren_nayar;
	}
	else {
		{output} = vec3(0.0);
	}
	"""
	
	return shader.format({
		"normal" : input_vars[0],
		"light" : input_vars[1],
		"view" : input_vars[2],
		"light_color" : input_vars[3],
		"attenuation" : input_vars[4],
		"diffuse_color" : input_vars[5],
		"sigma" : input_vars[6],
		"output" : output_vars[0]
		})
