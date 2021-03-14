struct SkyOutput {
    [[builtin(position)]] position: vec4<f32>;
    [[location(0)]] uv: vec3<f32>;
};

[[block]]
struct Data {
    // from camera to screen
    proj: mat4x4<f32>;
    // from screen to camera
    proj_inv: mat4x4<f32>;
    // from world to camera
    view: mat4x4<f32>;
    // camera position
    cam_pos: vec4<f32>;
};
[[group(0), binding(0)]]
var r_data: Data;

[[stage(vertex)]]
fn vs_sky([[builtin(vertex_index)]] vertex_index: u32) -> SkyOutput {
    // hacky way to draw a large triangle
    var tmp1: i32 = i32(vertex_index) / 2;
    var tmp2: i32 = i32(vertex_index) & 1;
    const pos: vec4<f32> = vec4<f32>(
        f32(tmp1) * 4.0 - 1.0,
        f32(tmp2) * 4.0 - 1.0,
        1.0,
        1.0
    );

    // transposition = inversion for this orthonormal matrix
    const inv_model_view: mat3x3<f32> = transpose(mat3x3<f32>(r_data.view.x.xyz, r_data.view.y.xyz, r_data.view.z.xyz));
    const unprojected: vec4<f32> = r_data.proj_inv * pos;

    var out: SkyOutput;
    out.uv = inv_model_view * unprojected.xyz;
    out.position = pos;
    return out;
}

struct EntityOutput {
    [[builtin(position)]] position: vec4<f32>;
    [[location(1)]] normal: vec3<f32>;
    [[location(3)]] view: vec3<f32>;
};

[[stage(vertex)]]
fn vs_entity(
    [[location(0)]] pos: vec3<f32>,
    [[location(1)]] normal: vec3<f32>,
) -> EntityOutput {
    var out: EntityOutput;
    out.normal = normal;
    out.view = pos - r_data.cam_pos.xyz;
    out.position = r_data.proj * r_data.view * vec4<f32>(pos, 1.0);
    return out;
}

[[group(0), binding(1)]]
var r_texture: texture_cube<f32>;
[[group(0), binding(2)]]
var r_sampler: sampler;

[[stage(fragment)]]
fn fs_sky(in: SkyOutput) -> [[location(0)]] vec4<f32> {
    return textureSample(r_texture, r_sampler, in.uv);
}

[[stage(fragment)]]
fn fs_entity(in: EntityOutput) -> [[location(0)]] vec4<f32> {
    const incident: vec3<f32> = normalize(in.view);
    const normal: vec3<f32> = normalize(in.normal);
    const reflected: vec3<f32> = incident - 2.0 * dot(normal, incident) * normal;

    const reflected_color: vec4<f32> = textureSample(r_texture, r_sampler, reflected);
    return vec4<f32>(0.1, 0.1, 0.1, 0.1) + 0.5 * reflected_color;
}