using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace AmazingAssets.TerrainToMesh.Example
{
    [RequireComponent(typeof(MeshFilter), typeof(MeshRenderer))]
    public class ExportMeshAndBasemapByPositionIndex : MonoBehaviour
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

        [Header("Chunk count is 4x4")]
        [Range(0, 3)]
        public int positionX;
        [Range(0, 3)] 
        public int positionY;

        [Space(10)]
        public Shader defaultShader;
        public Shader cutoutShader;


        int chunkCountHorizontal = 4;
        int chunkCountVertical = 4;


        void Start()
        {
            if (terrainData == null)
                return;


            //1. Export mesh from terrain by position///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
           
            Mesh terrainMesh = terrainData.TerrainToMesh().ExportMesh(vertexCountHorizontal, vertexCountVertical, chunkCountHorizontal, chunkCountVertical, positionX, positionY, true, TerrainToMesh.Normal.CalculateFromMesh);

            GetComponent<MeshFilter>().sharedMesh = terrainMesh;




            //2. Export basemap textures by position///////////////////////////////////////////////////////////////////////////////////////////////////////////////////

            Texture2D diffuseTexture = terrainData.TerrainToMesh().ExportBasemapDiffuseTexture(mapsResolution, chunkCountHorizontal, chunkCountVertical, positionX, positionY, exportHoles, false, enableHeightBasedBlend, heightTransition);  //Basemap's alpha channel contains holesmap, if 'exportHoles' is enabled
            Texture2D normalTexture = terrainData.TerrainToMesh().ExportBasemapNormalTexture(mapsResolution, chunkCountHorizontal, chunkCountVertical, positionX, positionY, false, enableHeightBasedBlend, heightTransition);
            
            Texture2D maskTexture = terrainData.TerrainToMesh().ExportBasemapMaskTexture(mapsResolution, chunkCountHorizontal, chunkCountVertical, positionX, positionY, false, enableHeightBasedBlend, heightTransition);       //Contains metallic(R), occlusion(G) and smoothness(A)



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