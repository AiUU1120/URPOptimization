#ifndef TERRAIN_TO_MESH_CORE_CGINC
#define TERRAIN_TO_MESH_CORE_CGINC


#include "Defines.cginc"
#include "Variables.cginc" 

#ifdef TERRAIN_TO_MESH_HLSL_GENERATED
	//Do nothing
#else
	#include "VariablesCBuffer.cginc"
#endif


float4 RemapMasks(float4 masks, float4 remapOffset, float4 remapScale)
{ 
	return remapOffset + masks * (remapScale - remapOffset);
} 

//Unity_NormalStrength_float
float3 TerrainToMeshNormalStrength(float3 In, float Strength)
{
	return float3(In.rg * Strength, lerp(1, In.b, saturate(Strength)));
}

float GetSumHeight(float4 heights)
{
    float sumHeight = heights.x;
    sumHeight += heights.y;
    sumHeight += heights.z;
    sumHeight += heights.w;

    return sumHeight;
}

inline float GammaToLinearSpaceExact (float value)
{
    if (value <= 0.04045F)
        return value / 12.92F;
    else if (value < 1.0F)
        return pow((saturate(value) + 0.055F)/1.055F, 2.4F);
    else
        return pow(saturate(value), 2.2F);
}


float TerrainToMeshCalculateClipValue(float2 uv)
{
	#if defined(_ALPHATEST_ON)

		float4 holesmap = T2M_UNPACK_HOLESMAP(uv);
		return holesmap.r;

	#else 
		
		return 1; 

	#endif 
} 

 
 
void TerrainToMeshCalculateLayersBlend(float2 uv, out float3 albedoValue, out float alphaValue, out float3 normalValue, out float metallicValue, out float smoothnessValue, out float occlusionValue)
{	
	#if defined(_T2M_TEXTURE_SAMPLE_TYPE_ARRAY)
		int paintMapUsageIndex = 0;
		int normalMapUsageIndex = 0;
		int maskMapUsageIndex = 0;
	#endif
	 


	//Splatmaps//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	float weights[16] = {0, 0, 0, 0, 
	                     0, 0, 0, 0,
					     0, 0, 0, 0,
					     0, 0, 0, 0};
	
	float4 splatmaps[4] = {T2M_ZERO_FLOAT4, T2M_ZERO_FLOAT4, T2M_ZERO_FLOAT4, T2M_ZERO_FLOAT4};



	T2M_UNPACK_SPLAT_MAP(splatmaps[0], uv, 0);
	weights[0] = splatmaps[0].r;
	weights[1] = splatmaps[0].g;
	weights[2] = splatmaps[0].b;
	weights[3] = splatmaps[0].a;

	#if defined(RENDER_SPLATMAP_1)
		T2M_UNPACK_SPLAT_MAP(splatmaps[1], uv, 1);
		weights[4] = splatmaps[1].r;
		weights[5] = splatmaps[1].g;
		weights[6] = splatmaps[1].b;
		weights[7] = splatmaps[1].a;
    #endif

	#if defined(RENDER_SPLATMAP_2)
		T2M_UNPACK_SPLAT_MAP(splatmaps[2], uv, 2);
		weights[8] = splatmaps[2].r; 
		weights[9] = splatmaps[2].g; 
		weights[10] = splatmaps[2].b; 
		weights[11] = splatmaps[2].a;
    #endif

	#if defined(RENDER_SPLATMAP_3)
		T2M_UNPACK_SPLAT_MAP(splatmaps[3], uv, 3);
		weights[12] = splatmaps[3].r; 
		weights[13] = splatmaps[3].g; 
		weights[14] = splatmaps[3].b; 
		weights[15] = splatmaps[3].a;
	#endif


	//UV///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	float2 layerUVs[16] = {T2M_ZERO_FLOAT2, T2M_ZERO_FLOAT2, T2M_ZERO_FLOAT2, T2M_ZERO_FLOAT2, 
						   T2M_ZERO_FLOAT2, T2M_ZERO_FLOAT2, T2M_ZERO_FLOAT2, T2M_ZERO_FLOAT2, 
						   T2M_ZERO_FLOAT2, T2M_ZERO_FLOAT2, T2M_ZERO_FLOAT2, T2M_ZERO_FLOAT2, 
						   T2M_ZERO_FLOAT2, T2M_ZERO_FLOAT2, T2M_ZERO_FLOAT2, T2M_ZERO_FLOAT2};


	CALCULATE_LAYER_UV(layerUVs[0], 0, uv)
	CALCULATE_LAYER_UV(layerUVs[1], 1, uv)
	#if defined(RENDER_LAYER_2)
		CALCULATE_LAYER_UV(layerUVs[2], 2, uv)
	#endif
	#if defined(RENDER_LAYER_3)
		CALCULATE_LAYER_UV(layerUVs[3], 3, uv)
	#endif
	#if defined(RENDER_LAYER_4)
		CALCULATE_LAYER_UV(layerUVs[4], 4, uv)
	#endif
	#if defined(RENDER_LAYER_5)
		CALCULATE_LAYER_UV(layerUVs[5], 5, uv)
	#endif
	#if defined(RENDER_LAYER_6)
		CALCULATE_LAYER_UV(layerUVs[6], 6, uv)
	#endif
	#if defined(RENDER_LAYER_7)
		CALCULATE_LAYER_UV(layerUVs[7], 7, uv)
	#endif
	#if defined(RENDER_LAYER_8)
		CALCULATE_LAYER_UV(layerUVs[8], 8, uv)
	#endif
	#if defined(RENDER_LAYER_9)
		CALCULATE_LAYER_UV(layerUVs[9], 9, uv)
	#endif
	#if defined(RENDER_LAYER_10)
		CALCULATE_LAYER_UV(layerUVs[10], 10, uv)
	#endif
	#if defined(RENDER_LAYER_11)
		CALCULATE_LAYER_UV(layerUVs[11], 11, uv)
	#endif
	#if defined(RENDER_LAYER_12)
		CALCULATE_LAYER_UV(layerUVs[12], 12, uv)
	#endif
	#if defined(RENDER_LAYER_13)
		CALCULATE_LAYER_UV(layerUVs[13], 13, uv)
	#endif
	#if defined(RENDER_LAYER_14)
		CALCULATE_LAYER_UV(layerUVs[14], 14, uv)
	#endif
	#if defined(RENDER_LAYER_15)
		CALCULATE_LAYER_UV(layerUVs[15], 15, uv)
	#endif


	//Masks///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	float4 emptyMask = float4(0.5, .5, .5, .5);
	float4 masks[16] = {emptyMask, emptyMask, emptyMask, emptyMask,
	                    emptyMask, emptyMask, emptyMask, emptyMask,
					    emptyMask, emptyMask, emptyMask, emptyMask,
					    emptyMask, emptyMask, emptyMask, emptyMask};
	 

	#if defined(_T2M_LAYER_0_MASK)
		T2M_UNPACK_MASK_MAP(0, masks[0], layerUVs[0])
	#endif 
	T2M_REMAP_MASK(0, masks[0])

	#if defined(_T2M_LAYER_1_MASK)
		T2M_UNPACK_MASK_MAP(1, masks[1], layerUVs[1])
	#endif 
	T2M_REMAP_MASK(1, masks[1])
	
	#if defined(RENDER_LAYER_2)
		#if defined(_T2M_LAYER_2_MASK)
			T2M_UNPACK_MASK_MAP(2, masks[2], layerUVs[2])
		#endif 
		T2M_REMAP_MASK(2, masks[2])
	#endif	

	#if defined(RENDER_LAYER_3)
		#if defined(_T2M_LAYER_3_MASK)
			T2M_UNPACK_MASK_MAP(3, masks[3], layerUVs[3])
		#endif 
		T2M_REMAP_MASK(3, masks[3])
	#endif

	#if defined(RENDER_LAYER_4)
		#if defined(_T2M_LAYER_4_MASK)
			T2M_UNPACK_MASK_MAP(4, masks[4], layerUVs[4])
		#endif 
		T2M_REMAP_MASK(4, masks[4])
	#endif

	#if defined(RENDER_LAYER_5)
		#if defined(_T2M_LAYER_5_MASK)
			T2M_UNPACK_MASK_MAP(5, masks[5], layerUVs[5])
		#endif 
		T2M_REMAP_MASK(5, masks[5])
	#endif

	#if defined(RENDER_LAYER_6)
		#if defined(_T2M_LAYER_6_MASK)
			T2M_UNPACK_MASK_MAP(6, masks[6], layerUVs[6])
		#endif 
		T2M_REMAP_MASK(6, masks[6])
	#endif
	
	#if defined(RENDER_LAYER_7)
		#if defined(_T2M_LAYER_7_MASK)
			T2M_UNPACK_MASK_MAP(7, masks[7], layerUVs[7])
		#endif 
		T2M_REMAP_MASK(7, masks[7])
	#endif

	#if defined(RENDER_LAYER_8)
		#if defined(_T2M_LAYER_8_MASK)
			T2M_UNPACK_MASK_MAP(8, masks[8], layerUVs[8])
		#endif 
		T2M_REMAP_MASK(8, masks[8])
	#endif

	#if defined(RENDER_LAYER_9)
		#if defined(_T2M_LAYER_9_MASK)
			T2M_UNPACK_MASK_MAP(9, masks[9], layerUVs[9])
		#endif 
		T2M_REMAP_MASK(9, masks[9])
	#endif

	#if defined(RENDER_LAYER_10)
		#if defined(_T2M_LAYER_10_MASK)
			T2M_UNPACK_MASK_MAP(10, masks[10], layerUVs[10])
		#endif 
		T2M_REMAP_MASK(10, masks[10])
	#endif

	#if defined(RENDER_LAYER_11)
		#if defined(_T2M_LAYER_11_MASK)
			T2M_UNPACK_MASK_MAP(11, masks[11], layerUVs[11])
		#endif 
		T2M_REMAP_MASK(11, masks[11])
	#endif

	#if defined(RENDER_LAYER_12)
		#if defined(_T2M_LAYER_12_MASK)
			T2M_UNPACK_MASK_MAP(12, masks[12], layerUVs[12])
		#endif 
		T2M_REMAP_MASK(12, masks[12])
	#endif

	#if defined(RENDER_LAYER_13)
		#if defined(_T2M_LAYER_13_MASK)
			T2M_UNPACK_MASK_MAP(13, masks[13], layerUVs[13])
		#endif 
		T2M_REMAP_MASK(13, masks[13])
	#endif

	#if defined(RENDER_LAYER_14)
		#if defined(_T2M_LAYER_14_MASK)
			T2M_UNPACK_MASK_MAP(14, masks[14], layerUVs[14])
		#endif 
		T2M_REMAP_MASK(14, masks[14])
	#endif

	#if defined(RENDER_LAYER_15)
		#if defined(_T2M_LAYER_15_MASK)
			T2M_UNPACK_MASK_MAP(15, masks[15], layerUVs[15])
		#endif 
		T2M_REMAP_MASK(15, masks[15])
	#endif


	//Diffuse Textures////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	float4 diffuse[16] = {T2M_ZERO_FLOAT4, T2M_ZERO_FLOAT4, T2M_ZERO_FLOAT4, T2M_ZERO_FLOAT4,
						  T2M_ZERO_FLOAT4, T2M_ZERO_FLOAT4, T2M_ZERO_FLOAT4, T2M_ZERO_FLOAT4,
					      T2M_ZERO_FLOAT4, T2M_ZERO_FLOAT4, T2M_ZERO_FLOAT4, T2M_ZERO_FLOAT4,
					      T2M_ZERO_FLOAT4, T2M_ZERO_FLOAT4, T2M_ZERO_FLOAT4, T2M_ZERO_FLOAT4};


	T2M_UNPACK_DIFFUSE_MAP(0, diffuse[0], layerUVs[0]);
    T2M_UNPACK_DIFFUSE_MAP(1, diffuse[1], layerUVs[1]);

	#if defined(RENDER_LAYER_2)
		T2M_UNPACK_DIFFUSE_MAP(2, diffuse[2], layerUVs[2]);
	#endif

	#if defined(RENDER_LAYER_3)
		T2M_UNPACK_DIFFUSE_MAP(3, diffuse[3], layerUVs[3]);
	#endif

	#if defined(RENDER_LAYER_4)
		T2M_UNPACK_DIFFUSE_MAP(4, diffuse[4], layerUVs[4]);
	#endif

	#if defined(RENDER_LAYER_5)
		T2M_UNPACK_DIFFUSE_MAP(5, diffuse[5], layerUVs[5]);
	#endif

	#if defined(RENDER_LAYER_6)
		T2M_UNPACK_DIFFUSE_MAP(6, diffuse[6], layerUVs[6]);
	#endif

	#if defined(RENDER_LAYER_7)
		T2M_UNPACK_DIFFUSE_MAP(7, diffuse[7], layerUVs[7]);
	#endif

	#if defined(RENDER_LAYER_8)
		T2M_UNPACK_DIFFUSE_MAP(8, diffuse[8], layerUVs[8]);
	#endif

	#if defined(RENDER_LAYER_9)
		T2M_UNPACK_DIFFUSE_MAP(9, diffuse[9], layerUVs[9]);
	#endif

	#if defined(RENDER_LAYER_10)
		T2M_UNPACK_DIFFUSE_MAP(10, diffuse[10], layerUVs[10]);
	#endif

	#if defined(RENDER_LAYER_11)
		T2M_UNPACK_DIFFUSE_MAP(11, diffuse[11], layerUVs[11]);
	#endif

	#if defined(RENDER_LAYER_12)
		T2M_UNPACK_DIFFUSE_MAP(12, diffuse[12], layerUVs[12]);
	#endif

	#if defined(RENDER_LAYER_13)
		T2M_UNPACK_DIFFUSE_MAP(13, diffuse[13], layerUVs[13]);
	#endif

	#if defined(RENDER_LAYER_14)
		T2M_UNPACK_DIFFUSE_MAP(14, diffuse[14], layerUVs[14]);
	#endif

	#if defined(RENDER_LAYER_15)
		T2M_UNPACK_DIFFUSE_MAP(15, diffuse[15], layerUVs[15]);
	#endif


	//URP Blend////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	#if !defined(RENDER_SPLATMAP_1) && !defined(RENDER_SPLATMAP_2) && !defined(RENDER_SPLATMAP_3)
				
		//Blending supports only 1 splatmaps (URP only)


		#ifdef _T2M_ENABLE_HEIGHT_BLEND

			// heights are in mask blue channel, we multiply by the splat Control weights to get combined height
			float4 splatHeight = float4(masks[0].b, masks[1].b, masks[2].b, masks[3].b) * splatmaps[0].rgba;
			half maxHeight = max(splatHeight.r, max(splatHeight.g, max(splatHeight.b, splatHeight.a)));

			// Ensure that the transition height is not zero.
			half transition = max(_T2M_HeightTransition, 1e-5);

			// This sets the highest splat to "transition", and everything else to a lower value relative to that, clamping to zero
			// Then we clamp this to zero and normalize everything
			float4 weightedHeights = splatHeight + transition - maxHeight.xxxx;
			weightedHeights = max(0, weightedHeights);

			// We need to add an epsilon here for active layers (hence the blendMask again)
			// so that at least a layer shows up if everything's too low.
			weightedHeights = (weightedHeights + 1e-6) * splatmaps[0];

			// Normalize (and clamp to epsilon to keep from dividing by zero)
			float sumHeight = max(dot(weightedHeights, float4(1, 1, 1, 1)), 1e-6);
			splatmaps[0] = weightedHeights / sumHeight.xxxx;

		#else 

			// Denser layers are more visible.
			float4 opacityAsDensity = saturate((float4(diffuse[0].a, diffuse[1].a, diffuse[2].a, diffuse[3].a) - (float4(1.0, 1.0, 1.0, 1.0) - splatmaps[0])) * 20.0); // 20.0 is the number of steps in inputAlphaMask (Density mask. We decided 20 empirically)
			opacityAsDensity += 0.001f * splatmaps[0];      // if all weights are zero, default to what the blend mask says
			float4 useOpacityAsDensityParam = { _T2M_Layer_0_OpacityAsDensity, _T2M_Layer_1_OpacityAsDensity, _T2M_Layer_2_OpacityAsDensity, _T2M_Layer_3_OpacityAsDensity }; // 1 is off
			splatmaps[0] = lerp(opacityAsDensity, splatmaps[0], 1 - useOpacityAsDensityParam);
				
			// Normalize
			float sumHeight = GetSumHeight(splatmaps[0]);
			splatmaps[0] = splatmaps[0] / sumHeight.xxxx;

		#endif


		//Update weights
		weights[0] = splatmaps[0].r;
		weights[1] = splatmaps[0].g;
		weights[2] = splatmaps[0].b;
		weights[3] = splatmaps[0].a;

	#endif

 
	//Albedo & Alpha////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	float4 paintColorSum = 0;
	UNITY_UNROLL for (int i = 0; i < LAYERS_COUNT; ++i)
	{
		paintColorSum += diffuse[i] * weights[i];
	}

	albedoValue = paintColorSum.rgb;
	alphaValue = paintColorSum.a;



	//Normal//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	#ifdef TERRAIN_TO_MESH_NEED_NORMAL

		normalValue = 0;


		#if defined(_T2M_LAYER_0_NORMAL)
			T2M_UNPACK_NORMAL_MAP(0, layerUVs[0], weights[0])
		#else 
			T2M_SUM_EMPTY_NORMAL(0, weights[0])
		#endif

		#if defined(_T2M_LAYER_1_NORMAL)
			T2M_UNPACK_NORMAL_MAP(1, layerUVs[1], weights[1])
		#else 
			T2M_SUM_EMPTY_NORMAL(1, weights[1])
		#endif

		#if defined(RENDER_LAYER_2)
			#if defined(_T2M_LAYER_2_NORMAL)
				T2M_UNPACK_NORMAL_MAP(2, layerUVs[2], weights[2])
			#else 
				T2M_SUM_EMPTY_NORMAL(2, weights[2])
			#endif
		#endif

		#if defined(RENDER_LAYER_3)
			#if defined(_T2M_LAYER_3_NORMAL)
				T2M_UNPACK_NORMAL_MAP(3, layerUVs[3], weights[3])
			#else 
				T2M_SUM_EMPTY_NORMAL(3, weights[3])
			#endif
		#endif

		#if defined(RENDER_LAYER_4)
			#if defined(_T2M_LAYER_4_NORMAL)
				T2M_UNPACK_NORMAL_MAP(4, layerUVs[4], weights[4])
			#else 
				T2M_SUM_EMPTY_NORMAL(4, weights[4])
			#endif
		#endif

		#if defined(RENDER_LAYER_5)
			#if defined(_T2M_LAYER_5_NORMAL)
				T2M_UNPACK_NORMAL_MAP(5, layerUVs[5], weights[5])
			#else 
				T2M_SUM_EMPTY_NORMAL(5, weights[5])
			#endif
		#endif

		#if defined(RENDER_LAYER_6)
			#if defined(_T2M_LAYER_6_NORMAL)
				T2M_UNPACK_NORMAL_MAP(6, layerUVs[6], weights[6])
			#else 
				T2M_SUM_EMPTY_NORMAL(6, weights[6])
			#endif
		#endif

		#if defined(RENDER_LAYER_7)
			#if defined(_T2M_LAYER_7_NORMAL)
				T2M_UNPACK_NORMAL_MAP(7, layerUVs[7], weights[7])
			#else 
				T2M_SUM_EMPTY_NORMAL(7, weights[7])
			#endif
		#endif

		#if defined(RENDER_LAYER_8)
			#if defined(_T2M_LAYER_8_NORMAL)
				T2M_UNPACK_NORMAL_MAP(8, layerUVs[8], weights[8])
			#else 
				T2M_SUM_EMPTY_NORMAL(8, weights[8])
			#endif
		#endif

		#if defined(RENDER_LAYER_9)
			#if defined(_T2M_LAYER_9_NORMAL)
				T2M_UNPACK_NORMAL_MAP(9, layerUVs[9], weights[9])
			#else 
				T2M_SUM_EMPTY_NORMAL(9, weights[9])
			#endif
		#endif

		#if defined(RENDER_LAYER_10)
			#if defined(_T2M_LAYER_10_NORMAL)
				T2M_UNPACK_NORMAL_MAP(10, layerUVs[10], weights[10])
			#else 
				T2M_SUM_EMPTY_NORMAL(10, weights[10])
			#endif
		#endif

		#if defined(RENDER_LAYER_11)
			#if defined(_T2M_LAYER_11_NORMAL)
				T2M_UNPACK_NORMAL_MAP(11, layerUVs[11], weights[11])
			#else 
				T2M_SUM_EMPTY_NORMAL(11, weights[11])
			#endif
		#endif

		#if defined(RENDER_LAYER_12)
			#if defined(_T2M_LAYER_12_NORMAL)
				T2M_UNPACK_NORMAL_MAP(12, layerUVs[12], weights[12])
			#else 
				T2M_SUM_EMPTY_NORMAL(12, weights[12])
			#endif
		#endif

		#if defined(RENDER_LAYER_13)
			#if defined(_T2M_LAYER_13_NORMAL)
				T2M_UNPACK_NORMAL_MAP(13, layerUVs[13], weights[13])
			#else 
				T2M_SUM_EMPTY_NORMAL(13, weights[13])
			#endif
		#endif

		#if defined(RENDER_LAYER_14)
			#if defined(_T2M_LAYER_14_NORMAL)
				T2M_UNPACK_NORMAL_MAP(14, layerUVs[14], weights[14])
			#else 
				T2M_SUM_EMPTY_NORMAL(14, weights[14])
			#endif
		#endif

		#if defined(RENDER_LAYER_15)
			#if defined(_T2M_LAYER_15_NORMAL)
				T2M_UNPACK_NORMAL_MAP(15, layerUVs[15], weights[15])
			#else 
				T2M_SUM_EMPTY_NORMAL(15, weights[15])
			#endif
		#endif

	#else

		normalValue = float3(0, 0, 1);

	#endif 



	//Metallic, Occlusion, Smoothness////////////////////////////////////////////////////////////////////////////////////////////////////////
	#ifdef TERRAIN_TO_MESH_NEED_METALLIC_SMOOTHNESS_OCCLUSION

		float4 metallicSmoothnessOcclusion = 0;


		#if defined(_T2M_LAYER_0_MASK)
			T2M_SUM_MASK(0, masks[0], weights[0]);
		#else				
			T2M_SUM_METALLIC_OCCLUSION_SMOOTHNESS(0, diffuse[0], weights[0]);
		#endif

		#if defined(_T2M_LAYER_1_MASK)
			T2M_SUM_MASK(1, masks[1], weights[1]);
		#else			
			T2M_SUM_METALLIC_OCCLUSION_SMOOTHNESS(1, diffuse[1], weights[1]);
		#endif

		#if defined(RENDER_LAYER_2)
			#if defined(_T2M_LAYER_2_MASK)
				T2M_SUM_MASK(2, masks[2], weights[2]);
			#else			
				T2M_SUM_METALLIC_OCCLUSION_SMOOTHNESS(2, diffuse[2], weights[2]);
			#endif
		#endif

		#if defined(RENDER_LAYER_3)
			#if defined(_T2M_LAYER_3_MASK)
				T2M_SUM_MASK(3, masks[3], weights[3]);
			#else			
				T2M_SUM_METALLIC_OCCLUSION_SMOOTHNESS(3, diffuse[3], weights[3]);
			#endif
		#endif

		#if defined(RENDER_LAYER_4)
			#if defined(_T2M_LAYER_4_MASK)
				T2M_SUM_MASK(4, masks[4], weights[4]);
			#else			
				T2M_SUM_METALLIC_OCCLUSION_SMOOTHNESS(4, diffuse[4], weights[4]);
			#endif
		#endif

		#if defined(RENDER_LAYER_5)
			#if defined(_T2M_LAYER_5_MASK)
				T2M_SUM_MASK(5, masks[5], weights[5]);
			#else			
				T2M_SUM_METALLIC_OCCLUSION_SMOOTHNESS(5, diffuse[5], weights[5]);
			#endif
		#endif

		#if defined(RENDER_LAYER_6)
			#if defined(_T2M_LAYER_6_MASK)
				T2M_SUM_MASK(6, masks[6], weights[6]);
			#else			
				T2M_SUM_METALLIC_OCCLUSION_SMOOTHNESS(6, diffuse[6], weights[6]);
			#endif
		#endif

		#if defined(RENDER_LAYER_7)
			#if defined(_T2M_LAYER_7_MASK)
				T2M_SUM_MASK(7, masks[7], weights[7]);
			#else			
				T2M_SUM_METALLIC_OCCLUSION_SMOOTHNESS(7, diffuse[7], weights[7]);
			#endif
		#endif

		#if defined(RENDER_LAYER_8)
			#if defined(_T2M_LAYER_8_MASK)
				T2M_SUM_MASK(8, masks[8], weights[8]);
			#else			
				T2M_SUM_METALLIC_OCCLUSION_SMOOTHNESS(8, diffuse[8], weights[8]);
			#endif
		#endif

		#if defined(RENDER_LAYER_9)
			#if defined(_T2M_LAYER_9_MASK)
				T2M_SUM_MASK(9, masks[9], weights[9]);
			#else			
				T2M_SUM_METALLIC_OCCLUSION_SMOOTHNESS(9, diffuse[9], weights[9]);
			#endif
		#endif

		#if defined(RENDER_LAYER_10)
			#if defined(_T2M_LAYER_10_MASK)
				T2M_SUM_MASK(10, masks[10], weights[10]);
			#else			
				T2M_SUM_METALLIC_OCCLUSION_SMOOTHNESS(10, diffuse[10], weights[10]);
			#endif
		#endif

		#if defined(RENDER_LAYER_11)
			#if defined(_T2M_LAYER_11_MASK)
				T2M_SUM_MASK(11, masks[11], weights[11]);
			#else			
				T2M_SUM_METALLIC_OCCLUSION_SMOOTHNESS(11, diffuse[11], weights[11]);
			#endif
		#endif

		#if defined(RENDER_LAYER_12)
			#if defined(_T2M_LAYER_12_MASK)
				T2M_SUM_MASK(12, masks[12], weights[12]);
			#else			
				T2M_SUM_METALLIC_OCCLUSION_SMOOTHNESS(12, diffuse[12], weights[12]);
			#endif
		#endif

		#if defined(RENDER_LAYER_13)
			#if defined(_T2M_LAYER_13_MASK)
				T2M_SUM_MASK(13, masks[13], weights[13]);
			#else			
				T2M_SUM_METALLIC_OCCLUSION_SMOOTHNESS(13, diffuse[13], weights[13]);
			#endif
		#endif

		#if defined(RENDER_LAYER_14)
			#if defined(_T2M_LAYER_14_MASK)
				T2M_SUM_MASK(14, masks[14], weights[14]);
			#else			
				T2M_SUM_METALLIC_OCCLUSION_SMOOTHNESS(14, diffuse[14], weights[14]);
			#endif
		#endif

		#if defined(RENDER_LAYER_15)
			#if defined(_T2M_LAYER_15_MASK)
				T2M_SUM_MASK(15, masks[15], weights[15]);
			#else			
				T2M_SUM_METALLIC_OCCLUSION_SMOOTHNESS(15, diffuse[15], weights[15]);
			#endif
		#endif



		metallicSmoothnessOcclusion = saturate(metallicSmoothnessOcclusion);

		metallicValue  = metallicSmoothnessOcclusion.r;
		occlusionValue = metallicSmoothnessOcclusion.g;
		smoothnessValue = metallicSmoothnessOcclusion.a;		

	#else

		metallicValue = 0;
		occlusionValue = 1;
		smoothnessValue = 0;		

	#endif	
}

#endif
 