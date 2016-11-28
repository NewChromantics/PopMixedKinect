using System.Collections;
using System.Collections.Generic;
using UnityEngine;


[RequireComponent(typeof(MeshFilter))]
[RequireComponent(typeof(MeshRenderer))]
public class KinectPointCloud : MonoBehaviour {

	public Texture	DepthTexture;
	public Texture	ColourTexture;

	[InspectorButton("RebuildMesh")]
	public bool		Dirty = true;
	public Mesh		CloudMesh;

	[Header("Get around vertex limit")]
	[Range(0,1)]
	public float	WidthScalar = 1.0f;
	[Range(0,1)]
	public float	HeightScalar = 1.0f;

	public void RebuildMesh()
	{
		CloudMesh = new Mesh();

		int Width = (int)(DepthTexture.width * WidthScalar);
		int Height = (int)(DepthTexture.height * HeightScalar);

		CloudMesh.name = "Point cloud " + Width + "x" + Height;
		//	make a point for each depth pixel
		var Positions = new List<Vector3>();
		var Indexes = new List<int>();
		{
			var Pos3 = new Vector3();
			for ( int y=0;	y<Height;	y++ )
			{
				if ( Positions.Count >= 65000 )
						break;

				for (int x = 0; x <Width; x++)
				{
					float xf = x/(float)Width;
					float yf = y/(float)Height;

					Pos3.x = xf * DepthTexture.width;
					Pos3.y = yf * DepthTexture.height;
					Positions.Add( Pos3 );
					Indexes.Add( Positions.Count-1 );

					if ( Positions.Count >= 65000 )
						break;
				}
			}
		}

		CloudMesh.SetVertices( Positions );
		CloudMesh.SetIndices( Indexes.ToArray(), MeshTopology.Points, 0, true );

		var mf = GetComponent<MeshFilter>();
		mf.sharedMesh = CloudMesh;

		var mr = GetComponent<MeshRenderer>();
		mr.sharedMaterial.SetTexture("DepthTexture",DepthTexture);
		mr.sharedMaterial.SetTexture("ColourTexture",ColourTexture);
	}


	void Update ()
	{
		if (Dirty)
		{
			RebuildMesh();
			Dirty = false;
		}		
	}
}
