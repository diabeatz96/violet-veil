using Godot;
using System;

public partial class AudioManager : Node
{
	
	AudioStreamPlayer[] musicPlayers;
	AudioStreamPlayer[] ambiencePlayers;
	AudioStreamPlayer SFXPlayers;

	//Create dictionaries to house the different audio files we will use
	Godot.Collections.Dictionary<String, AudioStream> musicTracks;
	Godot.Collections.Dictionary<String, AudioStream> ambienceTracks;
	Godot.Collections.Dictionary<String, AudioStream> SFXTracks;
    // Called when the node enters the scene tree for the first time.
    public override void _Ready()
	{

        //The audiostream players that we will use to play audio
        musicPlayers = new AudioStreamPlayer[2]
        {
            new AudioStreamPlayer(),
            new AudioStreamPlayer()
        };
        musicPlayers[0].Bus = "Music";
        musicPlayers[1].Bus = "Music";
        ambiencePlayers = new AudioStreamPlayer[2]
        {
            new AudioStreamPlayer(),
            new AudioStreamPlayer()
        };
        ambiencePlayers[0].Bus = "Ambience";
        ambiencePlayers[1].Bus = "Ambience";
        AudioStreamPlayer SFXPlayers = new AudioStreamPlayer();
        SFXPlayers.MaxPolyphony = 10; //This parameter determines how many unique sounds the player can play at once. Was originally going to have 10 unique players, but figured this should work
        SFXPlayers.Bus = "SFX";

       
                    

        //Instantiate the collections that will contain references to our audio files
        Godot.Collections.Dictionary<String, AudioStream> musicTracks = new Godot.Collections.Dictionary<String, AudioStream>();
		musicTracks[""] = GD.Load<AudioStream>("res://sounds/music");
        Godot.Collections.Dictionary<String, AudioStream> ambienceTracks = new Godot.Collections.Dictionary<String, AudioStream>();
        ambienceTracks[""] = GD.Load<AudioStream>("res://sounds/ambience");
        Godot.Collections.Dictionary<String, AudioStream> SFXTracks = new Godot.Collections.Dictionary<String, AudioStream>();
        SFXTracks[""] = GD.Load<AudioStream>("res://sounds/SFX");
    }
    /// <summary>
    /// Plays an individual sound effect. Accepts the name of the sound file we want to play
    /// </summary>
    public void PlaySFX(String SFXName)
    {
        SFXPlayers.Stream = SFXTracks[SFXName];
        SFXPlayers.Play();

    }
    //Start a chosen track
    public void StartMusic(String musicName)
    {
        stopMusic();
        musicPlayers[0].Stream = musicTracks[musicName];
        musicPlayers[0].Play();

    }
    //Stop a chosen track
    public void stopMusic()
    {
        musicPlayers[0].Stop();
        musicPlayers[1].Stop();
    }





}

