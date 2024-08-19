using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace AmazingAssets.TerrainToMesh.Example
{
    [RequireComponent(typeof(MeshFilter), typeof(MeshRenderer))]
    public class ExportMeshAndSplatmap : MonoBehaviour
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
        public bool createFallbackTextures;


        void Start()
        {
            if (terrainData == null)
                return;


            //1. Export mesh with edge fall/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

            Mesh terrainMesh = terrainData.TerrainToMesh().ExportMesh(vertexCountHorizontal, vertexCountVertical, TerrainToMesh.Normal.CalculateFromMesh);

            GetComponent<MeshFilter>().sharedMesh = terrainMesh;




            //2. Export Splatmap material from terrain/////////////////////////////////////////////////////////////////////////////////////////////////////////////////

            Material splatmapMaterial = terrainData.TerrainToMesh().ExportSplatmapMaterial(exportHoles, enableHeightBasedBlend, heightTransition);

            GetComponent<Renderer>().sharedMaterial = splatmapMaterial;




            //3. Fallback for Splatmap material

            if (createFallbackTextures)
            {
                Texture2D fallbackDiffuse = terrainData.TerrainToMesh().ExportBasemapDiffuseTexture(1024, exportHoles, false, enableHeightBasedBlend, heightTransition);  //Basemap's alpha channel contains holesmap, if 'exportHoles' is enabled
                Texture2D fallbackNormal = terrainData.TerrainToMesh().ExportBasemapNormalTexture(1024, false, enableHeightBasedBlend, heightTransition);


                //Depend on the used render pipeline, Unity's built-in Lit shader has different name for the '_MainTex' property
                splatmapMaterial.SetTexture(Utilities.GetMaterailPropMainTex(), fallbackDiffuse);
                splatmapMaterial.SetTexture(Utilities.GetMaterailPropBumpMap(), fallbackNormal);
            }
        }
    }
}