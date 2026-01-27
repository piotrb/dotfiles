#!/usr/bin/env ts-node

/**
 * GitHub Notifications Manager
 *
 * A convenience CLI for managing GitHub notifications with a better UX
 * than the native web interface at https://github.com/notifications
 */

import { Command } from 'commander';
import { listRepos } from './gh-notifications/repos';
import { listNotificationsForRepo } from './gh-notifications/for-repo';
import { dismissNotifications } from './gh-notifications/dismiss';

const program = new Command();

program
  .name('gh-notifications')
  .description(
    'GitHub Notifications Manager - A better CLI for managing GitHub notifications',
  )
  .version('1.0.0');

program
  .command('repos')
  .description('List repositories with notification counts')
  .option('--all', 'Show all notifications including read ones (default: unread only)')
  .action(async (options) => {
    await listRepos({ all: options.all });
  });

program
  .command('for_repo <repo>')
  .description('List notifications for a specific repository')
  .option('--all', 'Show all notifications including read ones (default: unread only)')
  .action(async (repo: string, options) => {
    await listNotificationsForRepo(repo, {
      all: options.all,
    });
  });

program
  .command('dismiss <repo>')
  .description('Dismiss notifications based on filters (at least one filter required)')
  .option('--reason <reason>', 'Filter by reason (valid: assign, author, comment, ci_activity, invitation, manual, mention, review_requested, security_alert, state_change, subscribed, team_mention)')
  .option('--type <type>', 'Filter by type (valid: CheckSuite, Commit, Discussion, Issue, PullRequest, Release, RepositoryVulnerabilityAlert, WorkflowRun)')
  .option('--pr-state <state>', 'Filter by PR state (valid: open, closed). Requires --type PullRequest')
  .option('--pr-draft <boolean>', 'Filter by PR draft status (true/false). Requires --type PullRequest')
  .option('--pr-merged <boolean>', 'Filter by PR merged status (true/false). Requires --type PullRequest')
  .option('--delete', 'Delete notifications instead of just marking them as read')
  .option('--all', 'Include read notifications (default: unread only)')
  .action(async (repo: string, options) => {
    await dismissNotifications({
      repo,
      reason: options.reason,
      type: options.type,
      prState: options.prState,
      prDraft: options.prDraft === 'true' ? true : options.prDraft === 'false' ? false : undefined,
      prMerged: options.prMerged === 'true' ? true : options.prMerged === 'false' ? false : undefined,
      delete: options.delete,
      all: options.all,
    });
  });

program.parse();
