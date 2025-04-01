import { describe, it, expect, beforeEach } from 'vitest';

// Mock functions to simulate Clarity behavior
const mockTxSender = 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM';
const mockDepartment = 'ST2CY5V39NHDPWSXMW9QDT3HC3GD6Q6XX4CFRK9AG';
const mockManager = 'ST3PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM';

// Mock state
let admin = mockTxSender;
let projectCounter = 0;
let projects = new Map();
let projectManagers = new Map();
let performanceMetrics = new Map();
let projectMilestones = new Map();

// Mock performance-measurement contract functions
function getProjectCount() {
  return projectCounter;
}

function getProject(projectId) {
  return projects.get(projectId);
}

function isProjectManager(address, projectId) {
  const key = `${projectId}-${address}`;
  return projectManagers.get(key)?.active || false;
}

function getPerformanceMetric(projectId, metricName) {
  const key = `${projectId}-${metricName}`;
  return performanceMetrics.get(key);
}

function getProjectMilestone(projectId, milestoneId) {
  const key = `${projectId}-${milestoneId}`;
  return projectMilestones.get(key);
}

function registerProject(sender, name, department, budget, duration) {
  if (sender !== admin) {
    return { error: 400 };
  }
  
  if (budget <= 0) {
    return { error: 401 };
  }
  
  if (duration <= 0) {
    return { error: 402 };
  }
  
  const projectId = projectCounter;
  projectCounter++;
  
  projects.set(projectId, {
    name,
    department,
    budget,
    startBlock: Date.now(), // Mock for block-height
    endBlock: Date.now() + duration // Mock for block-height + duration
  });
  
  return { value: true };
}

function addProjectManager(sender, projectId, manager) {
  if (sender !== admin) {
    return { error: 400 };
  }
  
  if (!projects.has(projectId)) {
    return { error: 403 };
  }
  
  const key = `${projectId}-${manager}`;
  projectManagers.set(key, { active: true });
  return { value: true };
}

function removeProjectManager(sender, projectId, manager) {
  if (sender !== admin) {
    return { error: 400 };
  }
  
  if (!projects.has(projectId)) {
    return { error: 403 };
  }
  
  const key = `${projectId}-${manager}`;
  projectManagers.set(key, { active: false });
  return { value: true };
}

function recordPerformanceMetric(sender, projectId, metricName, value) {
  if (!isProjectManager(sender, projectId)) {
    return { error: 404 };
  }
  
  if (!projects.has(projectId)) {
    return { error: 403 };
  }
  
  const key = `${projectId}-${metricName}`;
  performanceMetrics.set(key, {
    value,
    recordedBy: sender,
    timestamp: Date.now() // Mock for block-height
  });
  
  return { value: true };
}

function addProjectMilestone(sender, projectId, milestoneId, description, targetBlock) {
  if (!isProjectManager(sender, projectId)) {
    return { error: 404 };
  }
  
  if (!projects.has(projectId)) {
    return { error: 403 };
  }
  
  const key = `${projectId}-${milestoneId}`;
  projectMilestones.set(key, {
    description,
    targetBlock,
    completed: false,
    completionBlock: 0
  });
  
  return { value: true };
}

function completeProjectMilestone(sender, projectId, milestoneId) {
  if (!isProjectManager(sender, projectId)) {
    return { error: 404 };
  }
  
  const key = `${projectId}-${milestoneId}`;
  const milestone = projectMilestones.get(key);
  
  if (!milestone) {
    return { error: 405 };
  }
  
  if (milestone.completed) {
    return { error: 406 };
  }
  
  projectMilestones.set(key, {
    ...milestone,
    completed: true,
    completionBlock: Date.now() // Mock for block-height
  });
  
  return { value: true };
}

describe('Performance Measurement Contract', () => {
  beforeEach(() => {
    // Reset state before each test
    admin = mockTxSender;
    projectCounter = 0;
    projects = new Map();
    projectManagers = new Map();
    performanceMetrics = new Map();
    projectMilestones = new Map();
  });
  
  it('should register a project successfully', () => {
    const result = registerProject(mockTxSender, 'Road Construction', mockDepartment, 1000000, 5000);
    expect(result).toEqual({ value: true });
    
    const project = getProject(0);
    expect(project.name).toEqual('Road Construction');
    expect(project.department).toEqual(mockDepartment);
    expect(project.budget).toEqual(1000000);
  });
  
  it('should fail to register project if not admin', () => {
    const nonAdmin = 'ST4PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM';
    const result = registerProject(nonAdmin, 'Road Construction', mockDepartment, 1000000, 5000);
    expect(result).toEqual({ error: 400 });
  });
  
  it('should fail to register project with invalid budget', () => {
    const result = registerProject(mockTxSender, 'Road Construction', mockDepartment, 0, 5000);
    expect(result).toEqual({ error: 401 });
  });
  
  it('should fail to register project with invalid duration', () => {
    const result = registerProject(mockTxSender, 'Road Construction', mockDepartment, 1000000, 0);
    expect(result).toEqual({ error: 402 });
  });
  
  it('should add a project manager successfully', () => {
    registerProject(mockTxSender, 'Road Construction', mockDepartment, 1000000, 5000);
    const result = addProjectManager(mockTxSender, 0, mockManager);
    expect(result).toEqual({ value: true });
    expect(isProjectManager(mockManager, 0)).toBe(true);
  });
  
  it('should fail to add project manager to non-existent project', () => {
    const result = addProjectManager(mockTxSender, 999, mockManager);
    expect(result).toEqual({ error: 403 });
  });
  
  it('should remove a project manager successfully', () => {
    registerProject(mockTxSender, 'Road Construction', mockDepartment, 1000000, 5000);
    addProjectManager(mockTxSender, 0, mockManager);
    const result = removeProjectManager(mockTxSender, 0, mockManager);
    expect(result).toEqual({ value: true });
    expect(isProjectManager(mockManager, 0)).toBe(false);
  });
  
  it('should record a performance metric successfully', () => {
    registerProject(mockTxSender, 'Road Construction', mockDepartment, 1000000, 5000);
    addProjectManager(mockTxSender, 0, mockManager);
    
    const result = recordPerformanceMetric(mockManager, 0, 'completion-percentage', 75);
    expect(result).toEqual({ value: true });
    
    const metric = getPerformanceMetric(0, 'completion-percentage');
    expect(metric.value).toEqual(75);
    expect(metric.recordedBy).toEqual(mockManager);
  });
  
  it('should fail to record metric if not project manager', () => {
    registerProject(mockTxSender, 'Road Construction', mockDepartment, 1000000, 5000);
    const nonManager = 'ST4PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM';
    
    const result = recordPerformanceMetric(nonManager, 0, 'completion-percentage', 75);
    expect(result).toEqual({ error: 404 });
  });
  
  it('should add a project milestone successfully', () => {
    registerProject(mockTxSender, 'Road Construction', mockDepartment, 1000000, 5000);
    addProjectManager(mockTxSender, 0, mockManager);
    
    const result = addProjectMilestone(mockManager, 0, 1, 'Foundation complete', Date.now() + 1000);
    expect(result).toEqual({ value: true });
    
    const milestone = getProjectMilestone(0, 1);
    expect(milestone.description).toEqual('Foundation complete');
    expect(milestone.completed).toBe(false);
  });
  
  it('should complete a project milestone successfully', () => {
    registerProject(mockTxSender, 'Road Construction', mockDepartment, 1000000, 5000);
    addProjectManager(mockTxSender, 0, mockManager);
    addProjectMilestone(mockManager, 0, 1, 'Foundation complete', Date.now() + 1000);
    
    const result = completeProjectMilestone(mockManager, 0, 1);
    expect(result).toEqual({ value: true });
    
    const milestone = getProjectMilestone(0, 1);
    expect(milestone.completed).toBe(true);
    expect(milestone.completionBlock).toBeGreaterThan(0);
  });
  
  it('should fail to complete non-existent milestone', () => {
    registerProject(mockTxSender, 'Road Construction', mockDepartment, 1000000, 5000);
    addProjectManager(mockTxSender, 0, mockManager);
    
    const result = completeProjectMilestone(mockManager, 0, 999);
    expect(result).toEqual({ error: 405 });
  });
  
  it('should fail to complete already completed milestone', () => {
    registerProject(mockTxSender, 'Road Construction', mockDepartment, 1000000, 5000);
    addProjectManager(mockTxSender, 0, mockManager);
    addProjectMilestone(mockManager, 0, 1, 'Foundation complete', Date.now() + 1000);
    completeProjectMilestone(mockManager, 0, 1);
    
    const result = completeProjectMilestone(mockManager, 0, 1);
    expect(result).toEqual({ error: 406 });
  });
});
