import * as readline from 'readline';
import { getOctokit, PRDetails, formatNotificationCompact } from './utils';

interface DismissOptions {
  repo: string;
  reason?: string;
  type?: string;
  prState?: 'open' | 'closed';
  prDraft?: boolean;
  prMerged?: boolean;
  delete?: boolean;
  all?: boolean;
}

// Valid values for each filter
const VALID_REASONS = [
  'assign',
  'author',
  'comment',
  'ci_activity',
  'invitation',
  'manual',
  'mention',
  'review_requested',
  'security_alert',
  'state_change',
  'subscribed',
  'team_mention',
];

const VALID_TYPES = [
  'CheckSuite',
  'Commit',
  'Discussion',
  'Issue',
  'PullRequest',
  'Release',
  'RepositoryVulnerabilityAlert',
  'WorkflowRun',
];

function validateOptions(options: DismissOptions): void {
  // Require at least one filter besides repo
  const hasPrFilter = options.prState !== undefined || options.prDraft !== undefined
                      || options.prMerged !== undefined;

  if (!options.reason && !options.type && !hasPrFilter) {
    console.error('Error: At least one filter is required (--reason, --type, or PR filters)');
    console.error('This is a safety measure to prevent accidentally dismissing all notifications.');
    process.exit(1);
  }

  if (options.reason && !VALID_REASONS.includes(options.reason)) {
    console.error(`Invalid reason: ${options.reason}`);
    console.error(`Valid reasons: ${VALID_REASONS.join(', ')}`);
    process.exit(1);
  }

  if (options.type && !VALID_TYPES.includes(options.type)) {
    console.error(`Invalid type: ${options.type}`);
    console.error(`Valid types: ${VALID_TYPES.join(', ')}`);
    process.exit(1);
  }

  if (hasPrFilter && options.type && options.type !== 'PullRequest') {
    console.error('Error: PR filters (--pr-state, --pr-draft, --pr-merged) can only be used with --type PullRequest');
    process.exit(1);
  }
}

function extractPRNumber(url: string): number {
  const match = url.match(/\/pulls\/(\d+)$/);
  return match ? parseInt(match[1], 10) : 0;
}

async function fetchPRDetails(
  octokit: any,
  owner: string,
  repo: string,
  notifications: any[],
): Promise<Map<number, PRDetails>> {
  const prNumbers = notifications
    .map((n) => extractPRNumber(n.subject.url))
    .filter((n) => n > 0);

  const prDetailsMap = new Map<number, PRDetails>();

  if (prNumbers.length === 0) return prDetailsMap;

  if (prNumbers.length < 50) {
    console.log(`Fetching details for ${prNumbers.length} PRs...`);
    await Promise.all(
      prNumbers.map(async (prNumber) => {
        try {
          const { data: pr } = await octokit.pulls.get({
            owner,
            repo,
            pull_number: prNumber,
          });
          prDetailsMap.set(prNumber, {
            state: pr.state,
            draft: pr.draft || false,
            merged: pr.merged || false,
          });
        } catch (error) {
          console.error(`Failed to fetch PR #${prNumber}`);
        }
      }),
    );
  } else {
    console.log('Fetching all PRs from repository (optimized)...');
    const allPrs = await octokit.paginate(
      octokit.pulls.list,
      {
        owner, repo, state: 'all', per_page: 100,
      },
    );

    const prNumbersSet = new Set(prNumbers);

    allPrs.forEach((pr: any) => {
      if (prNumbersSet.has(pr.number)) {
        // The list endpoint doesn't reliably return the 'merged' field,
        // but we can use merged_at: if it's set, the PR is merged
        const merged = pr.merged_at !== null && pr.merged_at !== undefined;
        prDetailsMap.set(pr.number, {
          state: pr.state,
          draft: pr.draft || false,
          merged,
        });
      }
    });
  }

  return prDetailsMap;
}

function promptUser(question: string): Promise<string> {
  const rl = readline.createInterface({
    input: process.stdin,
    output: process.stdout,
  });

  return new Promise((resolve) => {
    rl.question(question, (answer) => {
      rl.close();
      resolve(answer);
    });
  });
}

export async function dismissNotifications(options: DismissOptions): Promise<void> {
  validateOptions(options);

  const octokit = getOctokit();

  console.log(`Fetching notifications for ${options.repo}...\n`);

  // Fetch all notifications
  const allNotifications = await octokit.paginate(
    octokit.activity.listNotificationsForAuthenticatedUser,
    { all: true, per_page: 100 },
  );

  // Filter by repository
  let notifications = allNotifications.filter(
    (n: any) => n.repository.full_name === options.repo,
  );

  // By default, only show unread notifications unless --all is specified
  if (!options.all) {
    notifications = notifications.filter((n: any) => n.unread);
  }

  if (notifications.length === 0) {
    console.log(`No notifications found for ${options.repo}`);
    return;
  }

  // Apply additional filters
  if (options.reason) {
    notifications = notifications.filter((n: any) => n.reason === options.reason);
  }

  if (options.type) {
    notifications = notifications.filter((n: any) => n.subject.type === options.type);
  }

  // Fetch PR details if needed
  let prDetailsMap = new Map<number, PRDetails>();
  const hasPrFilter = options.prState !== undefined || options.prDraft !== undefined
                      || options.prMerged !== undefined;

  if (options.type === 'PullRequest' || hasPrFilter) {
    const [owner, repo] = options.repo.split('/');
    const prNotifications = notifications.filter((n: any) => n.subject.type === 'PullRequest');
    prDetailsMap = await fetchPRDetails(octokit, owner, repo, prNotifications);
  }

  // Filter by PR attributes if specified
  if (hasPrFilter) {
    notifications = notifications.filter((n: any) => {
      const prNumber = extractPRNumber(n.subject.url);
      const prDetails = prDetailsMap.get(prNumber);

      if (!prDetails) return false;

      // Check each filter
      if (options.prState !== undefined && prDetails.state !== options.prState) {
        return false;
      }
      if (options.prDraft !== undefined && prDetails.draft !== options.prDraft) {
        return false;
      }
      if (options.prMerged !== undefined && prDetails.merged !== options.prMerged) {
        return false;
      }

      return true;
    });
  }

  if (notifications.length === 0) {
    console.log('No notifications match the specified criteria.');
    return;
  }

  // Display matching notifications
  console.log(`Found ${notifications.length} notification(s) matching criteria:\n`);
  console.log('Filters applied:');
  console.log(`  Repository: ${options.repo}`);
  if (options.reason) console.log(`  Reason: ${options.reason}`);
  if (options.type) console.log(`  Type: ${options.type}`);
  if (options.prState !== undefined) console.log(`  PR State: ${options.prState}`);
  if (options.prDraft !== undefined) console.log(`  PR Draft: ${options.prDraft}`);
  if (options.prMerged !== undefined) console.log(`  PR Merged: ${options.prMerged}`);
  console.log('');
  console.log('Notifications to dismiss:');
  console.log('─'.repeat(100));

  notifications.forEach((notification: any) => {
    const prNumber = notification.subject.type === 'PullRequest'
      ? extractPRNumber(notification.subject.url)
      : undefined;
    const prDetails = prNumber ? prDetailsMap.get(prNumber) : undefined;
    console.log(formatNotificationCompact(notification, prNumber, prDetails));
  });

  console.log('─'.repeat(100));
  console.log('');

  // Confirm with user
  const action = options.delete ? 'Delete' : 'Mark as read';
  const answer = await promptUser(`${action} ${notifications.length} notification(s)? [y/N]: `);

  if (answer.toLowerCase() !== 'y' && answer.toLowerCase() !== 'yes') {
    console.log('Cancelled.');
    return;
  }

  // Dismiss or delete notifications
  console.log(`\n${action}ing notifications...`);
  let successCount = 0;
  let errorCount = 0;

  for (const notification of notifications) {
    try {
      if (options.delete) {
        await octokit.activity.markThreadAsDone({
          thread_id: parseInt(notification.id, 10),
        });
      } else {
        await octokit.activity.markThreadAsRead({
          thread_id: parseInt(notification.id, 10),
        });
      }
      successCount++;
    } catch (error) {
      console.error(`Failed to ${options.delete ? 'delete' : 'dismiss'} notification ${notification.id}`);
      errorCount++;
    }
  }

  console.log(`\nDone! Successfully ${options.delete ? 'deleted' : 'marked as read'} ${successCount} notification(s).`);
  if (errorCount > 0) {
    console.log(`Failed to ${options.delete ? 'delete' : 'mark as read'} ${errorCount} notification(s).`);
  }
}
