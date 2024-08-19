Shader "Hidden/Amazing Assets/Terrain To Mesh/AllTerrainTextures"
{
	Properties 
	{
		_Color("", Color) = (1, 1, 1, 1)
		_MainTex("", 2D) = "white" {}
	}
	 


	CGINCLUDE

	#include "UnityCG.cginc"



	//Variables///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	float4 _Color;
	sampler2D _MainTex;
	float4 _MainTex_TexelSize; 

	UNITY_DECLARE_TEX2D (_SplatMap0);
	UNITY_DECLARE_TEX2D_NOSAMPLER (_SplatMap1);

	UNITY_DECLARE_TEX2D(_Map0);
	UNITY_DECLARE_TEX2D_NOSAMPLER(_Map1);
	UNITY_DECLARE_TEX2D_NOSAMPLER(_Map2);
	UNITY_DECLARE_TEX2D_NOSAMPLER(_Map3);
	UNITY_DECLARE_TEX2D_NOSAMPLER(_Map4);
	UNITY_DECLARE_TEX2D_NOSAMPLER(_Map5);
	UNITY_DECLARE_TEX2D_NOSAMPLER(_Map6);
	UNITY_DECLARE_TEX2D_NOSAMPLER(_Map7);

	float _RenderLayers[8];	
	float _MapsUsage[8];

	float4 _MapsRemapMin[8];
	float4 _MapsRemapMax[8];

	float4 _MapsUVScaleOffset[8];
	float4 _MapsSplitUVOffset;

	float _Data0;
	float _Data1;
	float _Data2;
	float _Data3;
	float _Data4;

	float _WorldSpaceUV;


	//Helper methods//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	void TerrainToWorldUV(float2 uv, out float2 mapUV, out float2 controlUV)
	{
		_MapsUVScaleOffset[0].zw += _MapsUVScaleOffset[0].xy * _MapsSplitUVOffset.zw;
		_MapsUVScaleOffset[0].xy *= _MapsSplitUVOffset.xy;

		controlUV = float2(uv * _MapsSplitUVOffset.xy + _MapsSplitUVOffset.zw);
		controlUV = lerp(controlUV, 1 - controlUV, _WorldSpaceUV);

		mapUV = float2(uv * _MapsUVScaleOffset[0].xy + _MapsUVScaleOffset[0].zw);	
		mapUV = lerp(mapUV, 1 - mapUV, _WorldSpaceUV);
	}

	void TerrainToWorldUV(float2 uv, out float2 mapUV[8], out float2 controlUV)
	{
		controlUV = lerp(uv, 1 - uv, _WorldSpaceUV);

		int i;
		for(i = 0; i < 8; i++)
		{
			mapUV[i] = float2(uv * _MapsUVScaleOffset[i].xy + _MapsUVScaleOffset[i].zw);		
			mapUV[i] = lerp(mapUV[i], 1 - mapUV[i], _WorldSpaceUV);
		}		
	}

	float2 RotateUV(float2 uv, float rotationDegree)
	{
		uv -= 0.5;
		float s = sin(rotationDegree);
		float c = cos(rotationDegree);
		float2x2 rMatrix = float2x2(c, -s, s, c);
		rMatrix *= 0.5;
		rMatrix += 0.5;
		rMatrix = rMatrix * 2 - 1;
		uv.xy = mul(uv.xy, rMatrix);
		uv += 0.5;

		return uv;
	}

	float Remap01(float value, float2 minMax)
	{
		value = (value - minMax.x) * (1.0 / (minMax.y - minMax.x));

		return saturate(value);
	}

	float4 Remap01(float4 value, float4 outMin, float4 outMax)
	{ 
		return outMin + value * (outMax - outMin);
	} 

	float4 RemapMasks(float4 masks, float4 remapOffset, float4 remapScale, float blendMask)
	{ 
		float4 ret = masks;
		ret.b *= blendMask; 
		ret = ret * remapScale + remapOffset;
		return ret;
	} 

	float3 HeightToNormal(float2 uv, float rotationDegree, float2 remapMinMax)
	{
    	float2 uvOffset = _MainTex_TexelSize * 1;


        float K1 = Remap01(tex2D(_MainTex, uv + float2( uvOffset.x * -1, uvOffset.y)).r, remapMinMax);
        float K2 = Remap01(tex2D(_MainTex, uv + float2(               0, uvOffset.y)).r, remapMinMax);
        float K3 = Remap01(tex2D(_MainTex, uv + float2(      uvOffset.x, uvOffset.y)).r, remapMinMax);

        float K4 = Remap01(tex2D(_MainTex, uv + float2( uvOffset.x * -1, 0)).r, remapMinMax);
        float K5 = Remap01(tex2D(_MainTex, uv + float2(               0, 0)).r, remapMinMax);
        float K6 = Remap01(tex2D(_MainTex, uv + float2(      uvOffset.x, 0)).r, remapMinMax);

        float K7 = Remap01(tex2D(_MainTex, uv + float2( uvOffset.x * -1, uvOffset.y * -1)).r, remapMinMax);
        float K8 = Remap01(tex2D(_MainTex, uv + float2(               0, uvOffset.y * -1)).r, remapMinMax);
        float K9 = Remap01(tex2D(_MainTex, uv + float2(      uvOffset.x, uvOffset.y * -1)).r, remapMinMax);




        float3 n;
        n.x = 60 * (K9 - K7 + 2 * (K6 - K4) + K3 - K1) * -1;
        n.y = 60 * (K1 - K7 + 2 * (K2 - K8) + K3 - K9) * -1;
        n.z = 1.0;

		if(rotationDegree > 1)
			n.xy *= -1;

        n = normalize(n);
			
		return n;
    }

	float GetSumHeight(float4 heights)
	{
		float sumHeight = heights.x;
		sumHeight += heights.y;
		sumHeight += heights.z;
		sumHeight += heights.w;

		return sumHeight;
	}

	float GetSumHeight(float4 heights0, float4 heights1)
	{
		float sumHeight = heights0.x;
		sumHeight += heights0.y;
		sumHeight += heights0.z;
		sumHeight += heights0.w;

		sumHeight += heights1.x;
		sumHeight += heights1.y;
		sumHeight += heights1.z;
		sumHeight += heights1.w;

		return sumHeight;
	}

	void HeightBasedSplatModifyURP(inout float4 splatControl, in float4 masks[4], float heightTransition)
	{
		// heights are in mask blue channel, we multiply by the splat Control weights to get combined height
		float4 splatHeight = float4(masks[0].b, masks[1].b, masks[2].b, masks[3].b) * splatControl.rgba;
		half maxHeight = max(splatHeight.r, max(splatHeight.g, max(splatHeight.b, splatHeight.a)));

		// Ensure that the transition height is not zero.
		half transition = max(heightTransition, 1e-5);

		// This sets the highest splat to "transition", and everything else to a lower value relative to that, clamping to zero
		// Then we clamp this to zero and normalize everything
		float4 weightedHeights = splatHeight + transition - maxHeight.xxxx;
		weightedHeights = max(0, weightedHeights);

		// We need to add an epsilon here for active layers (hence the blendMask again)
		// so that at least a layer shows up if everything's too low.
		weightedHeights = (weightedHeights + 1e-6) * splatControl;

		// Normalize (and clamp to epsilon to keep from dividing by zero)
		float sumHeight = max(dot(weightedHeights, float4(1, 1, 1, 1)), 1e-6);
		splatControl = weightedHeights / sumHeight.xxxx;
	}

	void HeightBasedSplatModifyHDRP(inout float4 splatmaps[2], float4 masks[8], float useSplatmap1, float heightTransition)
	{
		// Modify blendMask to take into account the height of the layer. Higher height should be more visible.
		float maxHeight = masks[0].z;
		maxHeight = max(maxHeight, masks[1].z);
		maxHeight = max(maxHeight, masks[2].z);
		maxHeight = max(maxHeight, masks[3].z);
		if(useSplatmap1 > 0.5)
		{
			maxHeight = max(maxHeight, masks[4].z);
			maxHeight = max(maxHeight, masks[5].z);
			maxHeight = max(maxHeight, masks[6].z);
			maxHeight = max(maxHeight, masks[7].z);
		}

		// Make sure that transition is not zero otherwise the next computation will be wrong.
		// The epsilon here also has to be bigger than the epsilon in the next computation.
		float transition = max(heightTransition, 1e-5);

		// The goal here is to have all but the highest layer at negative heights, then we add the transition so that if the next highest layer is near transition it will have a positive value.
		// Then we clamp this to zero and normalize everything so that highest layer has a value of 1.
		float4 weightedHeights0 = { masks[0].z, masks[1].z, masks[2].z, masks[3].z };
		weightedHeights0 = weightedHeights0 - maxHeight.xxxx;
		// We need to add an epsilon here for active layers (hence the blendMask again) so that at least a layer shows up if everything's too low.
		weightedHeights0 = (max(0, weightedHeights0 + transition) + 1e-6) * splatmaps[0];

		float4 weightedHeights1 = { 0, 0, 0, 0 };
		if(useSplatmap1 > 0.5)
		{
			weightedHeights1 = float4( masks[4].z, masks[5].z, masks[6].z, masks[7].z );
			weightedHeights1 = weightedHeights1 - maxHeight.xxxx;
			weightedHeights1 = (max(0, weightedHeights1 + transition) + 1e-6) * splatmaps[1];
		}

		// Normalize
		float sumHeight = GetSumHeight(weightedHeights0, weightedHeights1);
		splatmaps[0] = weightedHeights0 / sumHeight.xxxx;
		if(useSplatmap1 > 0.5)
		{
			splatmaps[1] = weightedHeights1 / sumHeight.xxxx;
		}
	}



	//frag////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	float4 fragBasemapDiffuse(v2f_img i) : SV_Target 
	{
		int splatmapChannelIndex = _Data0;
		float diffuseSmoothness  = _Data1;

		float2 mapUV, controlUV;
		TerrainToWorldUV(i.uv, mapUV, controlUV);


		float splatmap0 = UNITY_SAMPLE_TEX2D_SAMPLER (_SplatMap0, _SplatMap0, controlUV)[(int)splatmapChannelIndex];
		
		float4 diffuse  = UNITY_SAMPLE_TEX2D_SAMPLER (_Map0, _Map0, mapUV);

		float4 c = tex2D(_MainTex, i.uv) + diffuse * _Color * float4(1, 1, 1, diffuseSmoothness) * splatmap0;

		return c;
	} 

	float4 fragBasemapNormal(v2f_img i) : SV_Target
	{
		int splatmapChannelIndex = _Data0;
		float normalScale        = _Data1;
		float flipNormal         = _Data2;
		float mapUsage           = _MapsUsage[0];

		float2 mapUV, controlUV;
		TerrainToWorldUV(i.uv, mapUV, controlUV);
		

		float4 normal = float4(1, 0.5, 0.5, 0.5);
		if(mapUsage > 0.5)	
			normal = UNITY_SAMPLE_TEX2D_SAMPLER (_Map0, _Map0, mapUV);	
		

		//[-1, 1]
		normal = normal * 2 - 1;

		//Flip normal 
		normal.yw *= normalScale * lerp(1, -1, flipNormal);

		//[0, 1]
		normal = (normal + 1) / 2;


		float splatmap0 = UNITY_SAMPLE_TEX2D_SAMPLER (_SplatMap0, _SplatMap0, controlUV)[(int)splatmapChannelIndex];

		float4 c = tex2D(_MainTex, i.uv) + normal * splatmap0;

		return c;
	}

	float4 fragBasemapNormalUnpacked(v2f_img i) : SV_Target
	{
		float4 c = tex2D(_MainTex, i.uv);

		c.rgb = UnpackNormal(c) * 0.5 + 0.5;		

		c.rgb = lerp(c.rgb, 1 - c.rgb, _WorldSpaceUV);


		c.b = 1;
		c.a = 1;

		return c;
	}

	float4 fragBasemapMask(v2f_img i) : SV_Target 
	{
		int splatmapChannelIndex = _Data0;
		float smoothness         = _Data1;
		float metallic           = _Data2;
		float occlusion          = _Data3;
		float readSmoothnessFromDiffuseAlpha = _Data4;
		float mapsUsage                      = _MapsUsage[0];

		float2 mapUV, controlUV;
		TerrainToWorldUV(i.uv, mapUV, controlUV);
		

		float splatmap0 = UNITY_SAMPLE_TEX2D_SAMPLER (_SplatMap0, _SplatMap0, controlUV)[(int)splatmapChannelIndex];
		
		float4 c = tex2D(_MainTex, i.uv);	
		if(mapsUsage > 0.5)
		{
			float4 mask = UNITY_SAMPLE_TEX2D_SAMPLER(_Map1, _Map0, mapUV);
			mask = Remap01(mask, _MapsRemapMin[0], _MapsRemapMax[0]);


			c += mask * splatmap0;
		}
		else
		{
			float4 diffuse = UNITY_SAMPLE_TEX2D_SAMPLER (_Map0, _Map0, mapUV);
			float smoothnessValue = lerp(smoothness, diffuse.a, readSmoothnessFromDiffuseAlpha);

			float4 mask = float4(lerp(GammaToLinearSpaceExact(metallic), metallic, IsGammaSpace()), occlusion, 0, smoothnessValue);


			c += mask * splatmap0;
		}


		return c;
	}

	float4 fragBasemapMaskURP(v2f_img i) : SV_Target 
	{
		int splatmapChannelIndex = _Data0;
		float smoothness         = _Data1;
		float metallic           = _Data2;
		float occlusion          = _Data3;
		float readSmoothnessFromDiffuseAlpha = _Data4;
		float mapsUsage                      = _MapsUsage[0];

		float2 mapUV, controlUV;
		TerrainToWorldUV(i.uv, mapUV, controlUV);
		

		float splatmap0 = UNITY_SAMPLE_TEX2D_SAMPLER (_SplatMap0, _SplatMap0, controlUV)[(int)splatmapChannelIndex];
		
		float4 c = tex2D(_MainTex, i.uv);		
		if(mapsUsage > 0.5)
		{
			float4 mask = UNITY_SAMPLE_TEX2D_SAMPLER(_Map1, _Map0, mapUV);
			mask = Remap01(mask, _MapsRemapMin[0], _MapsRemapMax[0]); 


			c += mask * splatmap0;	
		} 
		else
		{
			float4 mask = float4(0.5, 0.5, 0.5, 0.5);
			mask = Remap01(mask, _MapsRemapMin[0], _MapsRemapMax[0]); 
			
			float4 diffuse = UNITY_SAMPLE_TEX2D_SAMPLER (_Map0, _Map0, mapUV);			

			mask = float4(lerp(GammaToLinearSpaceExact(GammaToLinearSpaceExact(metallic)), metallic, IsGammaSpace()), occlusion, 0, lerp(smoothness, diffuse.a, readSmoothnessFromDiffuseAlpha));


			c += mask * splatmap0;  
		}


		return c;
	} 

	float4 fragBasemapMaskHDRP(v2f_img i) : SV_Target 
	{
		int splatmapChannelIndex = _Data0;
		float smoothness         = _Data1;
		float metallic           = _Data2;
		float occlusion          = _Data3;
		float readSmoothnessFromDiffuseAlpha = _Data4;
		float mapsUsage                      = _MapsUsage[0];

		float2 mapUV, controlUV;
		TerrainToWorldUV(i.uv, mapUV, controlUV);
		

		float splatmap0 = UNITY_SAMPLE_TEX2D_SAMPLER (_SplatMap0, _SplatMap0, controlUV)[(int)splatmapChannelIndex];
		
		float4 c = tex2D(_MainTex, i.uv);
		if(mapsUsage > 0.5)
		{
			float4 mask    = UNITY_SAMPLE_TEX2D_SAMPLER(_Map1, _Map0, mapUV);
			mask = RemapMasks(mask, _MapsRemapMin[0], _MapsRemapMax[0], splatmap0);  
			mask = lerp(float4(0, 1, 0, 0), mask, splatmap0 > 0 ? 1 : 0);


			c += mask * splatmap0;	
		} 
		else
		{
			float4 mask = float4(0, 0, 0, 0);
			mask = lerp(float4(0, 1, 0, 0), mask, splatmap0 > 0 ? 1 : 0);

			float4 diffuse = UNITY_SAMPLE_TEX2D_SAMPLER (_Map0, _Map0, mapUV);

			mask = float4(GammaToLinearSpaceExact(metallic), occlusion, 0, lerp(smoothness, diffuse.a, readSmoothnessFromDiffuseAlpha));
		

			c += mask * splatmap0;  
		}


		return c;
	} 

	float4 fragBasemapSpecular(v2f_img i) : SV_Target 
	{
		return 0;
	} 

	float4 fragBasemapMetallic(v2f_img i) : SV_Target 
	{
		return 0;
	} 

	float4 fragBasemapSmoothness(v2f_img i) : SV_Target 
	{
		return 0;
	} 

	float4 fragBasemapOcclusion(v2f_img i) : SV_Target 
	{
		int splatmapChannelIndex = _Data0;
		float occlusion          = _Data1;


		float2 mapUV, controlUV;
		TerrainToWorldUV(i.uv, mapUV, controlUV);


		float splatmap0 = UNITY_SAMPLE_TEX2D_SAMPLER (_SplatMap0, _SplatMap0, controlUV)[(int)splatmapChannelIndex];

		float4 mask = UNITY_SAMPLE_TEX2D_SAMPLER(_Map0, _Map0, mapUV);

		float4 c = tex2D(_MainTex, i.uv) + float4(Remap01(mask * float4(0, occlusion, 0, 0), _MapsRemapMin[0], _MapsRemapMax[0]).ggg, 1) * splatmap0;

		return c;
	} 

	float4 fragGeneric(v2f_img i) : SV_Target 
	{
		float rotationDegree = _Data0;


		i.uv = RotateUV(i.uv, rotationDegree);

		float4 c = tex2D(_MainTex, i.uv);
		
		return c;
	} 

	float4 fragGenericHolesmap(v2f_img i) : SV_Target 
	{
		float rotationDegree = _Data0;


		i.uv = RotateUV(i.uv, rotationDegree);

		float4 c = tex2D(_MainTex, i.uv);

		return float4(c.xxx, 1);
	} 

	float4 fragGenericHeightmap(v2f_img i) : SV_Target 
	{
		return 0;
	} 

	float4 fragGenericHeightmapNormal(v2f_img i) : SV_Target 
	{
		return 0;
	} 

	float4 fragHolesToBasemap(v2f_img i) : SV_Target 
	{
		float4 c = tex2D(_MainTex, i.uv);
		float4 holes = UNITY_SAMPLE_TEX2D_SAMPLER(_SplatMap0, _SplatMap0, i.uv);

		c.a = holes.r;
		
		return c;
	} 

	float4 fragUnpackHeightFromMasksURP(v2f_img i) : SV_Target 
	{
		float heightTransition = _Data0;


		float2 mapUV[8];
		float2 controlUV;
		TerrainToWorldUV(i.uv, mapUV, controlUV);

		float4 controlMap = UNITY_SAMPLE_TEX2D_SAMPLER(_SplatMap0, _SplatMap0, controlUV);


		float4 masksMaps[4];
		masksMaps[0] = UNITY_SAMPLE_TEX2D_SAMPLER(_Map0, _Map0, mapUV[0]);
		masksMaps[1] = UNITY_SAMPLE_TEX2D_SAMPLER(_Map1, _Map0, mapUV[1]);
		masksMaps[2] = UNITY_SAMPLE_TEX2D_SAMPLER(_Map2, _Map0, mapUV[2]);
		masksMaps[3] = UNITY_SAMPLE_TEX2D_SAMPLER(_Map3, _Map0, mapUV[3]);


		float4 masks[4];
		for(int i = 0; i < 4; i++)
		{
			masks[i] = lerp(float4(0.5, 0.5, 0.5, 0.5), masksMaps[i], _MapsUsage[i] > 0.5 ? 1 : 0);
			masks[i] = Remap01(masks[i], _MapsRemapMin[i], _MapsRemapMax[i]);
		}


		HeightBasedSplatModifyURP(controlMap, masks, heightTransition);

		
		return controlMap;		
	} 

	float4 fragUnpackHeightFromMasksHDRP(v2f_img i) : SV_Target 
	{
		float heightTransition  = _Data0;
		float useSplatmap1      = _Data1;
		int returnSplatmapIndex = _Data2;
		


		float2 mapUV[8];
		float2 controlUV;
		TerrainToWorldUV(i.uv, mapUV, controlUV);

		float4 splatmaps[2];
		splatmaps[0] = UNITY_SAMPLE_TEX2D_SAMPLER(_SplatMap0, _SplatMap0, controlUV);
		if(useSplatmap1 > 0.5)
			splatmaps[1] = UNITY_SAMPLE_TEX2D_SAMPLER(_SplatMap1, _SplatMap0, controlUV);
		else
			splatmaps[1] = float4(0, 0, 0, 0);

		float weights[8];
		weights[0] = splatmaps[0].r;
		weights[1] = splatmaps[0].g;
		weights[2] = splatmaps[0].b;
		weights[3] = splatmaps[0].a;
		weights[4] = splatmaps[1].r;
		weights[5] = splatmaps[1].g;
		weights[6] = splatmaps[1].b;
		weights[7] = splatmaps[1].a;


		float4 masksMaps[8];
		masksMaps[0] = UNITY_SAMPLE_TEX2D_SAMPLER(_Map0, _Map0, mapUV[0]);
		masksMaps[1] = UNITY_SAMPLE_TEX2D_SAMPLER(_Map1, _Map0, mapUV[1]);
		masksMaps[2] = UNITY_SAMPLE_TEX2D_SAMPLER(_Map2, _Map0, mapUV[2]);
		masksMaps[3] = UNITY_SAMPLE_TEX2D_SAMPLER(_Map3, _Map0, mapUV[3]);
		if(useSplatmap1 > 0.5)
		{
			masksMaps[4] = UNITY_SAMPLE_TEX2D_SAMPLER(_Map4, _Map0, mapUV[4]);
			masksMaps[5] = UNITY_SAMPLE_TEX2D_SAMPLER(_Map5, _Map0, mapUV[5]);
			masksMaps[6] = UNITY_SAMPLE_TEX2D_SAMPLER(_Map6, _Map0, mapUV[6]);
			masksMaps[7] = UNITY_SAMPLE_TEX2D_SAMPLER(_Map7, _Map0, mapUV[7]);
		}
		else
		{
			masksMaps[4] = 0;
			masksMaps[5] = 0;
			masksMaps[6] = 0;
			masksMaps[7] = 0;
		}

		float4 masks[8];
		for(int i = 0; i < 8; i++)
		{
			if(_RenderLayers[i] > 0.5)
			{
				if(_MapsUsage[i] > 0.5)	
				{
					masks[i] = masksMaps[i];
					masks[i] = RemapMasks(masks[i], _MapsRemapMin[i], _MapsRemapMax[i], weights[i]);  
					masks[i] = lerp(float4(0, 1, _MapsRemapMin[i].z, 0), masks[i], weights[i] > 0 ? 1 : 0);
				}
				else
				{
					masks[i] = float4(0, 0, _MapsRemapMin[i].z + 0.5 * _MapsRemapMax[i].z, 0);  
					masks[i] = lerp(float4(0, 1, _MapsRemapMin[i].z, 0), masks[i], weights[i] > 0 ? 1 : 0);
				}
			}
			else
			{
				masks[i] = float4(0, 1, 0, 0);
			}
		}



		HeightBasedSplatModifyHDRP(splatmaps, masks, useSplatmap1, heightTransition);

		
		return splatmaps[returnSplatmapIndex];		
	} 


	float4 fragOpacityAsDensity(v2f_img i) : SV_Target 
	{
		float useSplatmap1      = _Data0;
		int returnSplatmapIndex = _Data1;


		float2 mapUV[8];
		float2 controlUV;
		TerrainToWorldUV(i.uv, mapUV, controlUV);

		float4 splatmaps[2];
		splatmaps[0] = UNITY_SAMPLE_TEX2D_SAMPLER(_SplatMap0, _SplatMap0, controlUV);
		if(useSplatmap1 > 0.5)
			splatmaps[1] = UNITY_SAMPLE_TEX2D_SAMPLER(_SplatMap1, _SplatMap0, controlUV);
		else
			splatmaps[1] = float4(0, 0, 0, 0);


		float4 diffuse[8];
		diffuse[0] = UNITY_SAMPLE_TEX2D_SAMPLER(_Map0, _Map0, mapUV[0]);
		diffuse[1] = UNITY_SAMPLE_TEX2D_SAMPLER(_Map1, _Map0, mapUV[1]);
		diffuse[2] = UNITY_SAMPLE_TEX2D_SAMPLER(_Map2, _Map0, mapUV[2]);
		diffuse[3] = UNITY_SAMPLE_TEX2D_SAMPLER(_Map3, _Map0, mapUV[3]);
		if(useSplatmap1 > 0.5)
		{
			diffuse[4] = UNITY_SAMPLE_TEX2D_SAMPLER(_Map4, _Map0, mapUV[4]);
			diffuse[5] = UNITY_SAMPLE_TEX2D_SAMPLER(_Map5, _Map0, mapUV[5]);
			diffuse[6] = UNITY_SAMPLE_TEX2D_SAMPLER(_Map6, _Map0, mapUV[6]);
			diffuse[7] = UNITY_SAMPLE_TEX2D_SAMPLER(_Map7, _Map0, mapUV[7]);
		}
		else
		{
			diffuse[4] = 0;
			diffuse[5] = 0;
			diffuse[6] = 0;
			diffuse[7] = 0;
		}

		// Denser layers are more visible.
		float4 opacityAsDensity0 = saturate((float4(diffuse[0].a, diffuse[1].a, diffuse[2].a, diffuse[3].a) - (float4(1.0, 1.0, 1.0, 1.0) - splatmaps[0])) * 20.0); // 20.0 is the number of steps in inputAlphaMask (Density mask. We decided 20 empirically)
		opacityAsDensity0 += 0.001f * splatmaps[0];      // if all weights are zero, default to what the blend mask says
		float4 useOpacityAsDensityParam0 = { _MapsRemapMin[0].w, _MapsRemapMin[1].w, _MapsRemapMin[2].w, _MapsRemapMin[3].w }; // 1 is off
		splatmaps[0] = lerp(opacityAsDensity0, splatmaps[0], 1 - useOpacityAsDensityParam0);
		
		if(useSplatmap1 > 0.5)
		{
			float4 opacityAsDensity1 = saturate((float4(diffuse[4].a, diffuse[5].a, diffuse[6].a, diffuse[7].a) - (float4(1.0, 1.0, 1.0, 1.0) - splatmaps[1])) * 20.0); // 20.0 is the number of steps in inputAlphaMask (Density mask. We decided 20 empirically)
			opacityAsDensity1 += 0.001f * splatmaps[1];  // if all weights are zero, default to what the blend mask says
			float4 useOpacityAsDensityParam1 = { _MapsRemapMin[4].w, _MapsRemapMin[5].w, _MapsRemapMin[6].w, _MapsRemapMin[7].w };
			splatmaps[1] = lerp(opacityAsDensity1, splatmaps[1], 1 - useOpacityAsDensityParam1);
		}

		// Normalize
		float sumHeight = GetSumHeight(splatmaps[0], splatmaps[1]);
		splatmaps[0] = splatmaps[0] / sumHeight.xxxx;
		
		if(useSplatmap1 > 0.5)
		{
			splatmaps[1] = splatmaps[1] / sumHeight.xxxx;
		}


		return splatmaps[returnSplatmapIndex];		
	} 

	ENDCG 
	

	SubShader    
	{				    
		Pass	//0
	    {
			ZTest Always Cull Off ZWrite Off

			CGPROGRAM
			#pragma vertex vert_img
	    	#pragma fragment fragBasemapDiffuse
			ENDCG

		} //Pass
		
		Pass	//1
	    {
			ZTest Always Cull Off ZWrite Off

			CGPROGRAM
			#pragma vertex vert_img 
	    	#pragma fragment fragBasemapNormal
			ENDCG

		} //Pass

		Pass	//2
	    {
			ZTest Always Cull Off ZWrite Off

			CGPROGRAM
			#pragma vertex vert_img
	    	#pragma fragment fragBasemapNormalUnpacked
			ENDCG

		} //Pass

		Pass	//3
	    {
			ZTest Always Cull Off ZWrite Off

			CGPROGRAM
			#pragma vertex vert_img
	    	#pragma fragment fragBasemapMask
			ENDCG

		} //Pass

		Pass	//4
	    {
			ZTest Always Cull Off ZWrite Off

			CGPROGRAM
			#pragma vertex vert_img
	    	#pragma fragment fragBasemapMaskURP
			ENDCG

		} //Pass

		Pass	//5
	    {
			ZTest Always Cull Off ZWrite Off

			CGPROGRAM
			#pragma vertex vert_img
	    	#pragma fragment fragBasemapMaskHDRP
			ENDCG

		} //Pass

		Pass	//6
	    {
			ZTest Always Cull Off ZWrite Off

			CGPROGRAM
			#pragma vertex vert_img
	    	#pragma fragment fragBasemapSpecular
			ENDCG

		} //Pass

		Pass	//7
	    {
			ZTest Always Cull Off ZWrite Off

			CGPROGRAM
			#pragma vertex vert_img
	    	#pragma fragment fragBasemapMetallic
			ENDCG

		} //Pass

		Pass	//8
	    {
			ZTest Always Cull Off ZWrite Off

			CGPROGRAM
			#pragma vertex vert_img
	    	#pragma fragment fragBasemapSmoothness
			ENDCG

		} //Pass

		Pass	//9
	    {
			ZTest Always Cull Off ZWrite Off

			CGPROGRAM
			#pragma vertex vert_img
	    	#pragma fragment fragBasemapOcclusion
			ENDCG

		} //Pass

		Pass	//10
	    {
			ZTest Always Cull Off ZWrite Off

			CGPROGRAM
			#pragma vertex vert_img
	    	#pragma fragment fragGeneric
			ENDCG

		} //Pass

		Pass	//11
	    {
			ZTest Always Cull Off ZWrite Off

			CGPROGRAM
			#pragma vertex vert_img
	    	#pragma fragment fragGenericHolesmap
			ENDCG

		} //Pass

		Pass	//12
	    {
			ZTest Always Cull Off ZWrite Off

			CGPROGRAM
			#pragma vertex vert_img
	    	#pragma fragment fragGenericHeightmap
			ENDCG

		} //Pass

		Pass	//13
	    {
			ZTest Always Cull Off ZWrite Off

			CGPROGRAM
			#pragma vertex vert_img
	    	#pragma fragment fragGenericHeightmapNormal
			ENDCG

		} //Pass

		Pass	//14
	    {
			ZTest Always Cull Off ZWrite Off

			CGPROGRAM
			#pragma vertex vert_img
	    	#pragma fragment fragHolesToBasemap
			ENDCG

		} //Pass

		Pass	//15
	    {
			ZTest Always Cull Off ZWrite Off

			CGPROGRAM
			#pragma vertex vert_img
	    	#pragma fragment fragUnpackHeightFromMasksURP
			ENDCG

		} //Pass

		Pass	//16
	    {
			ZTest Always Cull Off ZWrite Off

			CGPROGRAM
			#pragma vertex vert_img
	    	#pragma fragment fragUnpackHeightFromMasksHDRP
			ENDCG

		} //Pass

		Pass	//17
	    {
			ZTest Always Cull Off ZWrite Off

			CGPROGRAM
			#pragma vertex vert_img
	    	#pragma fragment fragOpacityAsDensity
			ENDCG

		} //Pass

	} //SubShader
	 
} //Shader
