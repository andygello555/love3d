float _gridSize = 3.0;

vec4 position(mat4 transform_projection, vec4 vertex_position)
{
    mat4 screen_transform = mat4(love_ScreenSize.x / (2 * vertex_position.w), 0.0                                        , 0.0                    , 0.0,   // first column
                                 0.0                                        , love_ScreenSize.y / (2 * vertex_position.w), 0.0                    , 0.0,   // second column
                                 0.0                                        , 0.0                                        , 1.0 / vertex_position.w, 0.0,   // third column
                                 love_ScreenSize.x / 2.0                    , love_ScreenSize.y / 2.0                    , 0.0                    , 1.0);  // fourth column

    vertex_position.z = 0.0; vertex_position.w = 1.0;
    vertex_position = screen_transform * vertex_position;
    vertex_position /= _gridSize;
    vertex_position.x = floor(vertex_position.x);
    vertex_position.y = floor(vertex_position.y);
    vertex_position *= _gridSize;
    return transform_projection * vertex_position;
}