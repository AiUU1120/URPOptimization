using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace AmazingAssets.TerrainToMesh.Example
{
    [RequireComponent(typeof(MeshFilter), typeof(MeshRenderer))]
    public class ExportMeshAndBasemap : MonoBehaviour
    {
        public TerrainData terrainData;

        public int vertexCountHorizontal = 100;
        public int vertexCountVertical = 100;

        [Space(10)]
        public bool enableHeightBasedBlend = false;
        [Range(0f, 1f)]
        public float heightTransition = 0;

        [Space(10)]
        public bool exportHoles = false;
        public int mapsResolution = 512;

        [Space(10)]
        public Shader defaultShader;
        public Shader cutoutShader;


        void Start()
        {
            if (terrainData == null)
                return;


            //1. Export mesh from terrain////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

            Mesh terrainMesh = terrainData.TerrainToMesh().ExportMesh(vertexCountHorizontal, vertexCountVertical, TerrainToMesh.Normal.CalculateFromMesh);

            GetComponent<MeshFilter>().sharedMesh = terrainMesh;




            //2. Export basemap textures////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

            Texture2D diffuseTexture = terrainData.TerrainToMesh().ExportBasemapDiffuseTexture(mapsResolution, exportHoles, false, enableHeightBasedBlend, heightTransition);  //Basemap's alpha channel contains holesmap, if 'exportHoles' is enabled
            Texture2D normalTexture = terrainData.TerrainToMesh().ExportBasemapNormalTexture(mapsResolution, false, enableHeightBasedBlend, heightTransition);

            Texture2D maskTexture = terrainData.TerrainToMesh().ExportBasemapMaskTexture(mapsResolution, false, enableHeightBasedBlend, heightTransition);       //Contains metallic(R), occlusion(G) and smoothness(A)


            //3. Create material and assign exported basemaps/////////////////////////////////////////////////////////////////////////////////////////////////

            Material material = new Material(exportHoles ? cutoutShader : defaultShader);


            material.SetTexture("_MainTex", diffuseTexture);    //Prop names are defined inside used shader
            material.SetTexture("_BumpMap", normalTexture);


            if (maskTexture != null)
            {
                material.SetTexture("_Mask", maskTexture);
                material.SetFloat("_Smoothness", 1);
            }


            GetComponent<Renderer>().sharedMaterial = material;
        }
    }
}