using System.Collections.Generic;
using UnityEngine;

public interface IFSMState {
  public virtual void OnEnterState(FSM fsm) {; }
  public virtual void OnExitState(FSM fsm) {; }
  public virtual void UpdateState(FSM fsm) {; }
  public virtual void TransferState(FSM fsm) {; }
}

public abstract class FSM : MonoBehaviour, IFSMState {
  private string m_curr_state_name;
  protected IFSMState m_curr_state;
  protected Dictionary<string, IFSMState> m_states;
  protected abstract void ConstructStates();
  protected abstract void EnterInitState();
  private class ErrorState : IFSMState { }
  protected virtual void Start() {
    ConstructStates();
    EnterInitState();
  }
  protected virtual void Update() {
    m_curr_state?.UpdateState(this);
  }
  protected virtual void FixedUpdate() {; }

  public virtual void UpdateFSM() {
    m_curr_state.TransferState(this);
  }

  public virtual void TransferState(string next_state_name) {
    if (!m_states.ContainsKey(next_state_name)) {
      Debug.LogError("FSMState " + next_state_name + " not found");
      m_curr_state.OnExitState(this);
      m_curr_state = new ErrorState();
      return;
    }
    IFSMState next_state = m_states[next_state_name];
    m_curr_state_name = next_state_name;
    m_curr_state?.OnExitState(this);
    m_curr_state = next_state;
    m_curr_state.OnEnterState(this);
  }
}
