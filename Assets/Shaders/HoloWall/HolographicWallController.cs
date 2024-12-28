using UnityEngine;

public class HolographicWallController : MonoBehaviour
{
    public Material[] wallMaterials; // Assign materials for all walls
    public Transform player;         // Reference to the player's transform

    void Update()
    {
        Vector3 playerPos = player.position;

        foreach (var mat in wallMaterials)
        {
            mat.SetVector("_PlayerPosition", playerPos);
        }
    }
}
