import test from 'node:test';
import assert from 'node:assert/strict';

import { testOnly } from './main.js';

test('editableData separates onboarding skill from profile fields', () => {
  const result = testOnly.editableData({
    name: '  Player One  ',
    email: 'player@example.com ',
    skill_level: ' Competitive ',
    roles: ['admin'],
  });

  assert.deepEqual(result, {
    skillLevel: 'competitive',
    data: {
      name: 'Player One',
      email: 'player@example.com',
    },
  });
});

test('editableData ignores invalid onboarding skill values', () => {
  const result = testOnly.editableData({
    name: 'Player Two',
    email: 'player2@example.com',
    skill_level: 'advanced',
  });

  assert.deepEqual(result, {
    skillLevel: '',
    data: {
      name: 'Player Two',
      email: 'player2@example.com',
    },
  });
});

test('editableData normalizes gender values and removes invalid genders', () => {
  assert.deepEqual(testOnly.editableData({ gender: ' non-binary ' }), {
    skillLevel: '',
    data: { gender: 'non_binary' },
  });

  assert.deepEqual(testOnly.editableData({ gender: 'prefer_not_to_say' }), {
    skillLevel: '',
    data: {},
  });
});

test('normalizeExistingUpdateData keeps only valid roles and drops protected relationships', () => {
  const result = testOnly.normalizeExistingUpdateData(
    {
      roles: ['normal_user', 'host', 'legacy'],
      membership_level_id: { $id: 'bronze' },
      job_title_verified_by: null,
    },
    { bio: 'Updated bio' },
  );

  assert.deepEqual(result, {
    bio: 'Updated bio',
    roles: ['user', 'host'],
  });
});

test('initialUserRowData assigns the bronze membership level to new users', () => {
  assert.deepEqual(
    testOnly.initialUserRowData({
      name: 'Player One',
      email: 'player@example.com',
    }),
    {
      name: 'Player One',
      email: 'player@example.com',
      roles: ['user'],
      membership_level_id: testOnly.DEFAULT_MEMBERSHIP_LEVEL_ID,
      job_title_verified: false,
    },
  );
});

test('normalizedSkillLevel accepts only active onboarding levels', () => {
  assert.equal(testOnly.normalizedSkillLevel('beginner'), 'beginner');
  assert.equal(testOnly.normalizedSkillLevel('Intermediate'), 'intermediate');
  assert.equal(testOnly.normalizedSkillLevel(' competitive '), 'competitive');
  assert.equal(testOnly.normalizedSkillLevel('advanced'), '');
  assert.equal(testOnly.normalizedSkillLevel(null), '');
});

test('normalizedRolesForWrite defaults to user when no valid roles exist', () => {
  assert.deepEqual(testOnly.normalizedRolesForWrite(['normal_user']), ['user']);
  assert.deepEqual(testOnly.normalizedRolesForWrite(['unknown']), ['user']);
});
