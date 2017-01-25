using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class RecordVideoTexture : MonoBehaviour {

	[InspectorButton("Stop")]
	public bool				_Stop;

	public Texture			Input;
	public PopCastParams	Params;
	public string			Filename = "file:streamingassets/*.mp4";
	public PopCast			Cast;
	public bool				EnableDebugLog = true;

	void Start()
	{
		if ( Params == null )
			Params = new PopCastParams();

		if ( Application.isPlaying )
		{
			Cast = new PopCast( Filename, Params );
			PopCast.EnableDebugLog = EnableDebugLog;
		}
	}

	void Update () {
	
		if ( Cast != null && Input != null )
			Cast.UpdateTexture( Input, 0 );
		
		PopCast.Update();
	}

	public void Stop()
	{
		if ( Cast != null )
		{
			Debug.Log("Freeing cast");
			Cast.Free();
			Cast = null;
		}
	}

}
