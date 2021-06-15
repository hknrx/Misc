// Nicolas Robert [Nrx]
using UnityEngine;
using UnityEngine.EventSystems;

public class FullScreenRender : MonoBehaviour, IPointerClickHandler
{
	// GUI
	public GameObject gui;

	// Script that handles the maze
	public Maze maze;

	// Toggle the GUI
	public void OnPointerClick (PointerEventData eventData)
	{
		gui.SetActive (!gui.activeSelf);
	}

	// Method called by Unity after a camera finished rendering the scene
	private void OnPostRender ()
	{
		maze.RenderFullScreen ();
	}
}
