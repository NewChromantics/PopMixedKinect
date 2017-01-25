using UnityEngine;
using System.Collections;


/// <summary>
///		PopMovieSimple is a very simple example of how to use a PopMovie instance to
///		play a movie to a specified texture using games timedelta to control the playback.
/// </summary>
[AddComponentMenu("PopMovie/PopMovieKinect")]
public class PopMovieKinect : MonoBehaviour {

	public Texture			ColourTexture;
	public Texture			DepthTexture;
	public string			Filename = "kinect:0";

	public PopMovieParams	Parameters;
	public PopMovie			Movie;
	float					MovieTime = 0;

	public bool				PlayOnAwake = true;

	[Tooltip("Enable debug logging when movie starts. Same as the global option, but automatically turns it on")]
	public bool				EnableDebugLog = false;

	void Awake() {

		if (PlayOnAwake ) {
			Play ();
		}
	}

	public void Play()
	{
		if (Movie == null) {
			Movie = new PopMovie (Filename, Parameters, MovieTime);
			if ( EnableDebugLog )
				PopMovie.EnableDebugLog = true;
		}

	}

	public void Stop()
	{
		if ( Movie != null )
		{
			Movie.Free ();
			Movie = null;
		}
		MovieTime = 0;
	}

	public void UpdateTextures()
	{
		if (Movie != null && ColourTexture != null)
			Movie.UpdateTexture (ColourTexture, 0);

		if (Movie != null && DepthTexture != null)
			Movie.UpdateTexture (DepthTexture, 1);
	}

	public void Update () {

		if (Movie != null)
		{
			MovieTime += Time.deltaTime;
			Movie.SetTime (MovieTime);

			UpdateTextures();
		}

	}

	
}
