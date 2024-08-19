using System.Collections;
using System.Collections.Generic;
using UnityEngine;


namespace AmazingAssets.TerrainToMesh.Example
{
    [RequireComponent(typeof(MeshFilter), typeof(MeshRenderer))]
    public class ExportMeshWithEdgeFall : MonoBehaviour
    {
        public TerrainData terrainData;

        public int vertexCountHorizontal = 100;
        public int vertexCountVertical = 100;

        [Space(10)]
        public EdgeFall edgeFall = new EdgeFall(0, true);
        public Texture2D edgeFallTexture;

        [Space(10)]
        public Shader defaultShader;


        void Start()
        {
            if (terrainData == null)
                return;


            //Export mesh with edge fall/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

            Mesh terrainMesh = terrainData.TerrainToMesh().ExportMesh(vertexCountHorizontal, vertexCountVertical, TerrainToMesh.Normal.CalculateFromMesh, edgeFall);

            GetComponent<MeshFilter>().sharedMesh = terrainMesh;




            //2. Create materials////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
                     
            Material meshMaterial = new Material(defaultShader);        //Material for the main mesh 

            Material edgeFallMaterial = new Material(defaultShader);    //Material for the edge fall (saved in the sub-mesh)
            edgeFallMaterial.SetTexture("_MainTex", edgeFallTexture);   //Prop name is defined inside used shader


            GetComponent<Renderer>().sharedMaterials = new Material[] { meshMaterial, edgeFallMaterial };
        }
    }
}
