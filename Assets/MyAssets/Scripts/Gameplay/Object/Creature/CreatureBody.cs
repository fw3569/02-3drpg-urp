using System.Collections.Generic;
using Unity.Burst.Intrinsics;
using UnityEngine;
using UnityEngine.UI;

[RequireComponent(typeof(Animator))]
public class CreatureBody : MonoBehaviour {
  protected Animator m_animator;
  public Status status = new();
  public GameObject weapon;
  private readonly HashSet<uint> m_atkbox_seqs = new();
  [SerializeField] private GameObject m_life_gauge;
  public ParticleSystem bloom_effect;
  protected virtual void Awake() {
    m_animator = GetComponent<Animator>();
  }
  protected virtual void ResetTriggers() {; }
  internal int DamageFuntion(AttackBox atkbox) {
    return atkbox.atk - status.def;
  }
  internal void Damaged(AttackBox atkbox) {
    status.life -= DamageFuntion(atkbox);
  }
  internal void UpdateGauge() {
    if (m_life_gauge != null) {
      m_life_gauge.GetComponent<Slider>().value = status.life * 1.0f / status.life_max;
    }
  }
  protected virtual void Stagger(AttackBox atkbox) {
    m_animator.SetTrigger("Stagger");
    m_animator.SetBool("InStagger", true);
  }
  protected virtual void Dead() {
    m_animator.SetTrigger("Dead");
    m_animator.SetBool("InDead", true);
  }
  protected virtual void OnHitEffect(Collider col) {
    if (bloom_effect != null) {
      bloom_effect.Play();
    }
  }
  private void OnHit(Collider col, AttackBox atkbox) {
    OnHitEffect(col);
    if (status.life <= 0.0f) {
      return;
    }
    Damaged(atkbox);
    UpdateGauge();
    if (status.life <= 0) {
      Dead();
    } else {
      Stagger(atkbox);
    }
  }
  void OnTriggerEnter(Collider col) {
    if (col.TryGetComponent(out AttackBox atkbox) && !CompareTag(atkbox.tag)) {
      if (!m_atkbox_seqs.Contains(atkbox.seq)) {
        m_atkbox_seqs.Add(atkbox.seq);
        OnHit(col, atkbox);
      }
    }
  }
}
