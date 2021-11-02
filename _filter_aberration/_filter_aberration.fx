#include "GameMaker.fxh"

// compile as:
// fxc /Ges /Vi /T fx_2_0 /Fo _filter_aberration.fxb _filter_aberration.fx

// Attributes
attribute vec3 in_Position;
attribute vec3 in_Normal; // (usually unused)
attribute vec4 in_Colour;
attribute vec2 in_TextureCoord;

// aka GLSL vars:
// GLSL ES has only one render target, so one element in the array.
// if we had more than one target, we'd increment this array's size.
static vec4 gl_Color[1];
static vec4 gl_Position;

varying vec2 v_vTexcoord;
varying vec4 v_vColour;

// registers s0 and c0 are reserved by GameMaker.fxh and are passed by the IDE
// they should NOT be used.

// uniforms go here:
uniform float u_Distance : register(c1);


// Vertex Shader main:
void Vgl_main()
{
    vec4 object_space_pos = vec4(in_Position.x, in_Position.y, in_Position.z, 1.0);
    // in IDE shaders we don't have gm_Matrices, but we have an MVPTransform uniform
    // which is the matrix we need to multiply by.
    gl_Position = mul(object_space_pos, MVPTransform);
    v_vColour = in_Colour;
    v_vTexcoord = in_TextureCoord;
}

// Fragment Shader main:
void Pgl_main()
{
    vec4 Color1 = gltexture2D( gm_BaseTexture, v_vTexcoord )/3.0;
    vec4 Color2 = gltexture2D( gm_BaseTexture, v_vTexcoord+0.002*u_Distance )/3.0;
    vec4 Color3 = gltexture2D( gm_BaseTexture, v_vTexcoord-0.002*u_Distance )/3.0;
    Color1 *= 2.0;
    Color2.g = 0.0;
    Color2.b = 0.0;
    Color3.r = 0.0;
    gl_FragColor = v_vColour * (Color1 + Color2 + Color3);
}

VS_OUTPUT Vmain(VS_INPUT input)
{
    in_Position = input._in_Position;
    in_Normal = input._in_Normal;
    in_Colour = input._in_Colour;
    in_TextureCoord = input._in_TextureCoord;

    Vgl_main();

    VS_OUTPUT output;
    output.gl_Position.x = gl_Position.x;
    output.gl_Position.y = gl_Position.y;
    output.gl_Position.z = gl_Position.z;
    output.gl_Position.w = gl_Position.w;
    output.v0 = v_vColour;
    output.v1 = v_vTexcoord;

    return output;
}

PS_OUTPUT Pmain(VS_OUTPUT input)
{
    v_vColour = input.v0;
    v_vTexcoord = input.v1.xy;

    Pgl_main();

    PS_OUTPUT output;
    output.gl_Color0 = gl_Color[0];
    return output;
}

technique _filter_glitchShader
{
    pass MainPass1
    {
        VertexShader = compile vs_3_0 Vmain();
        PixelShader  = compile ps_3_0 Pmain();
    }
}
