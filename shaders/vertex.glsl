// vec4 position(mat4 transform_projection, vec4 vertex_position)
// {
//     // The order of operations matters when doing matrix multiplication.
//     return transform_projection * vertex_position;
// }

float _gridSize = 2.5;

vec4 position(mat4 transform_projection, vec4 vertex_position)
{
    vertex_position /= _gridSize;
    vertex_position.x = floor(vertex_position.x);
    vertex_position.y = floor(vertex_position.y);
    vertex_position.z = floor(vertex_position.z);
    vertex_position *= _gridSize;
    return transform_projection * vertex_position;
}