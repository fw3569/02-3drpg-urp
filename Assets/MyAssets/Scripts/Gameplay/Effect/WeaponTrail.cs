using System.Collections.Generic;
using System.Linq;
using UnityEngine;

public class WeaponTrail : MonoBehaviour {
  public GameObject start;
  public GameObject end;
  Mesh m_mesh;
  public List<Color> colors;
  public bool generating = false;
  public float alive_time = 0;
  public float fade_time;
  public class TrailSegment {
    public float created_time;
    public List<Vector3> vertex;
  }
  readonly List<TrailSegment> m_trail_segments = new();
  public float max_diatence;
  public float generate_interval;
  float m_next_generate_time = 0;
  public Material material;
  void Awake() {
    m_mesh = new();
  }
  void Update() {
    UpdateMesh();
    Graphics.DrawMesh(m_mesh, Matrix4x4.identity, material, LayerMask.NameToLayer("Ignore"));
  }
  void UpdateMesh() {
    float time = Time.time;
    float earliest_create_time = time - alive_time;
    int delete_count = 0;
    while (m_trail_segments.Count != 0) {
      if (m_trail_segments[0].created_time <= earliest_create_time) {
        m_trail_segments.RemoveAt(0);
        ++delete_count;
      } else {
        break;
      }
    }
    if (delete_count != 0 || generating) {
      int vertex_count = colors.Count;
      {
        List<Vector3> mesh_vertices = new(m_mesh.vertices);
        List<Color> mesh_colors = new(m_mesh.colors);
        List<int> mesh_triangles = new(m_mesh.triangles);
        mesh_vertices.RemoveRange(0, delete_count * vertex_count);
        mesh_colors.RemoveRange(0, delete_count * vertex_count);
        if (generating) {
          if (m_next_generate_time == 0 || m_next_generate_time < time || (start.transform.position - mesh_vertices[^vertex_count]).magnitude > max_diatence || (end.transform.position - mesh_vertices[^1]).magnitude > max_diatence) {
            m_next_generate_time = time + generate_interval;
            m_trail_segments.Add(new());
            m_trail_segments[^1].created_time = time;
            Vector3 dir = (end.transform.position - start.transform.position) / (vertex_count - 1);
            for (int i = 0; i < vertex_count; ++i) {
              mesh_vertices.Add(start.transform.position + dir * i);
            }
            mesh_colors.AddRange(colors);
            if (delete_count == 0 && m_trail_segments.Count >= 2) {
              for (int i = 1, index1 = mesh_vertices.Count - vertex_count * 2, index2 = mesh_vertices.Count - vertex_count; i < vertex_count; ++i, ++index1, ++index2) {
                mesh_triangles.Add(index1);
                mesh_triangles.Add(index2);
                mesh_triangles.Add(index2 + 1);
                mesh_triangles.Add(index2 + 1);
                mesh_triangles.Add(index1 + 1);
                mesh_triangles.Add(index1);
              }
            }
          }
        }
        int triangle_count = Mathf.Max((m_trail_segments.Count - 1) * (vertex_count - 1) * 6, 0);
        if (mesh_triangles.Count > triangle_count) {
          mesh_triangles.RemoveRange(triangle_count, mesh_triangles.Count - triangle_count);
        }
        if (mesh_vertices.Count > m_mesh.vertices.Count()) {
          m_mesh.vertices = mesh_vertices.ToArray();
          m_mesh.colors = mesh_colors.ToArray();
          m_mesh.triangles = mesh_triangles.ToArray();
        } else {
          m_mesh.triangles = mesh_triangles.ToArray();
          m_mesh.vertices = mesh_vertices.ToArray();
          m_mesh.colors = mesh_colors.ToArray();
        }
      }
      // m_mesh.RecalculateNormals();
      // m_mesh.RecalculateTangents();
      // m_mesh.RecalculateBounds();
    }
    if (fade_time != alive_time) {
      int index = 0;
      float fade_duration = alive_time - fade_time;
      var mesh_colors = m_mesh.colors;
      foreach (TrailSegment segment in m_trail_segments) {
        float a = 1 - Mathf.Max(time - segment.created_time - fade_time, 0) / fade_duration;
        for (int i = 0; i < colors.Count; ++i) {
          mesh_colors[index].a = colors[i].a * a;
          ++index;
        }
      }
      m_mesh.colors = mesh_colors;
    }
  }
}