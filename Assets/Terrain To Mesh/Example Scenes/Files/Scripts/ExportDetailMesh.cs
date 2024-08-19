using System.Collections;
using System.Collections.Generic;
using UnityEngine;


namespace AmazingAssets.TerrainToMesh.Example
{
    [RequireComponent(typeof(MeshFilter), typeof(MeshRenderer))]
    public class ExportDetailMesh : MonoBehaviour
    {
        public TerrainData terrainData;

        public int vertexCountHorizontal = 100;
        public int vertexCountVertical = 100;

        [Space(10)]
        public Material material;


        void Start()
        {
            if (terrainData == null)
                return;


            //1. Export mesh from terrain////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

            Mesh terrainMesh = terrainData.TerrainToMesh().ExportMesh(vertexCountHorizontal, vertexCountVertical, TerrainToMesh.Normal.CalculateFromMesh);

            GetComponent<MeshFilter>().sharedMesh = terrainMesh;




            //2. Create material////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

            GetComponent<Renderer>().sharedMaterial = material;




            //3. Export grass//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

            DetailPrototypesData[] detailPrototypesData = terrainData.TerrainToMesh().ExportDetailMeshData(vertexCountHorizontal, vertexCountVertical, 1, 1, 8);


            for (int t = 0; t < detailPrototypesData.Length; t++)
            {
                for (int p = 0; p < detailPrototypesData[t].position.Count; p++)
                {
                    //Instantiate detail mesh prefab
                    GameObject detailPrototype = Instantiate(detailPrototypesData[t].detailPrototype.prototype);

                    //Set position
                    detailPrototype.transform.position = detailPrototypesData[t].position[p];

                    //Add rotation
                    detailPrototype.transform.rotation = Quaternion.Euler(0, Random.value * 360, 0);

                    //Scale
                    detailPrototype.transform.localScale = detailPrototypesData[t].scale[p];


                    //Add parent
                    detailPrototype.transform.SetParent(this.gameObject.transform, false);
                }
            }
        }
    }
}
