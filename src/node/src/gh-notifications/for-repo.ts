import { getOctokit, PRDetails, formatNotificationCompact } from './utils';

interface TypeBreakdown {
  [key: string]: number;
}

interface NotificationStats {
  total: number;
  unread: number;
  read: number;
  byReason: TypeBreakdown;
  bySubjectType: TypeBreakdown;
}

interface PRNotificationWithDetails {
  notification: any;
  prNumber: number;
  pr?: any;
}

interface WorkflowRunNotificationWithDetails {
  notification: any;
  runId: number;
  run?: any;
}

export async function listNotificationsForRepo(
  repoFullName: string,
  options?: { all?: boolean },
): Promise<void> {
  const octokit = getOctokit();

  console.log(`Fetching notifications for ${repoFullName}...\n`);

  // Fetch all notifications with pagination
  const allNotifications = await octokit.paginate(
    octokit.activity.listNotificationsForAuthenticatedUser,
    { all: true, per_page: 100 },
  );

  // Filter for the specific repository
  let repoNotifications = allNotifications.filter(
    (notification) => notification.repository.full_name === repoFullName,
  );

  // By default, only show unread notifications unless --all is specified
  if (!options?.all) {
    repoNotifications = repoNotifications.filter((n) => n.unread);
  }

  if (repoNotifications.length === 0) {
    console.log(`No notifications found for ${repoFullName}`);
    return;
  }

  // Calculate stats
  const stats: NotificationStats = {
    total: repoNotifications.length,
    unread: repoNotifications.filter((n) => n.unread).length,
    read: repoNotifications.filter((n) => !n.unread).length,
    byReason: {},
    bySubjectType: {},
  };

  repoNotifications.forEach((notification) => {
    const reason = notification.reason || 'unknown';
    const subjectType = notification.subject.type || 'unknown';

    stats.byReason[reason] = (stats.byReason[reason] || 0) + 1;
    stats.bySubjectType[subjectType] = (stats.bySubjectType[subjectType] || 0) + 1;
  });

  // Display summary
  console.log(`Repository: ${repoFullName}`);
  console.log(`Total: ${stats.total} (${stats.unread} unread, ${stats.read} read)\n`);

  // Fetch PR and workflow run details
  let prDetailsWithNotifications: PRNotificationWithDetails[] = [];
  let workflowRunDetailsWithNotifications: WorkflowRunNotificationWithDetails[] = [];

  const [owner, repo] = repoFullName.split('/');

  const prNotifications = repoNotifications.filter(
    (n) => n.subject.type === 'PullRequest',
  );

  if (prNotifications.length > 0) {
    console.log(`Fetching details for ${prNotifications.length} pull request(s)...\n`);
    prDetailsWithNotifications = await fetchPullRequestDetails(
      octokit,
      owner,
      repo,
      prNotifications,
    );
  }

  const workflowRunNotifications = repoNotifications.filter(
    (n) => n.subject.type === 'WorkflowRun',
  );

  if (workflowRunNotifications.length > 0) {
    console.log(`Fetching details for ${workflowRunNotifications.length} workflow run(s)...\n`);
    workflowRunDetailsWithNotifications = await fetchWorkflowRunDetails(
      octokit,
      owner,
      repo,
      workflowRunNotifications,
    );
  }

  // Show by-type breakdown with PR status
  if (true) {
    // Show by reason
    const reasons = Object.entries(stats.byReason).sort((a, b) => b[1] - a[1]);
    if (reasons.length > 0) {
      console.log('By Reason:');
      reasons.forEach(([reason, count]) => {
        console.log(`  • ${reason}: ${count}`);
      });
      console.log('');
    }

    // Show by subject type with PR status breakdown
    const types = Object.entries(stats.bySubjectType).sort((a, b) => b[1] - a[1]);
    if (types.length > 0) {
      console.log('By Type:');
      types.forEach(([type, count]) => {
        console.log(`  • ${type}: ${count}`);

        // If this is PullRequest type and we have PR details, show breakdown
        if (type === 'PullRequest' && prDetailsWithNotifications.length > 0) {
          const stateCounts: { [key: string]: number } = {};
          let draftCount = 0;
          let mergedCount = 0;

          prDetailsWithNotifications.forEach((item) => {
            if (item.pr) {
              stateCounts[item.pr.state] = (stateCounts[item.pr.state] || 0) + 1;
              if (item.pr.draft) draftCount++;
              if (item.pr.merged) mergedCount++;
            }
          });

          // Show state breakdown
          const sortedStates = Object.entries(stateCounts).sort((a, b) => b[1] - a[1]);
          sortedStates.forEach(([state, stateCount]) => {
            console.log(`    └─ state=${state}: ${stateCount}`);
          });

          // Show draft and merged counts
          if (draftCount > 0) {
            console.log(`    └─ draft=true: ${draftCount}`);
          }
          if (mergedCount > 0) {
            console.log(`    └─ merged=true: ${mergedCount}`);
          }
        }

        // If this is WorkflowRun type and we have workflow run details, show breakdown
        if (type === 'WorkflowRun' && workflowRunDetailsWithNotifications.length > 0) {
          const statusCounts: { [key: string]: number } = {};
          const conclusionCounts: { [key: string]: number } = {};
          let waitingCount = 0;
          let noUrlCount = 0;

          workflowRunDetailsWithNotifications.forEach((item) => {
            if (item.run) {
              statusCounts[item.run.status] = (statusCounts[item.run.status] || 0) + 1;
              if (item.run.conclusion) {
                conclusionCounts[item.run.conclusion] = (conclusionCounts[item.run.conclusion] || 0) + 1;
              }
              // Check if waiting for approval
              if (item.run.status === 'waiting' || item.run.status === 'action_required') {
                waitingCount++;
              }
            } else if (!item.notification.subject.url) {
              noUrlCount++;
            }
          });

          // Show status breakdown
          const sortedStatuses = Object.entries(statusCounts).sort((a, b) => b[1] - a[1]);
          sortedStatuses.forEach(([status, statusCount]) => {
            console.log(`    └─ status=${status}: ${statusCount}`);
          });

          // Show conclusion breakdown
          if (Object.keys(conclusionCounts).length > 0) {
            const sortedConclusions = Object.entries(conclusionCounts).sort((a, b) => b[1] - a[1]);
            sortedConclusions.forEach(([conclusion, conclusionCount]) => {
              console.log(`    └─ conclusion=${conclusion}: ${conclusionCount}`);
            });
          }

          // Show waiting for approval count
          if (waitingCount > 0) {
            console.log(`    └─ waiting_for_approval: ${waitingCount}`);
          }

          // Show count of notifications without URL
          if (noUrlCount > 0) {
            console.log(`    └─ no_url (cannot fetch): ${noUrlCount}`);
          }
        }
      });
      console.log('');
    }
  }

  // Show full PR details grouped by status
  if (prDetailsWithNotifications.length > 0) {
    // Group by PR state
    const groupedByState = new Map<string, PRNotificationWithDetails[]>();

    prDetailsWithNotifications.forEach((item) => {
      const state = item.pr?.state || 'unknown';

      if (!groupedByState.has(state)) {
        groupedByState.set(state, []);
      }
      groupedByState.get(state)!.push(item);
    });

    // Display PRs grouped by state
    console.log('Pull Requests by State:\n');
    const stateOrder = ['open', 'closed', 'unknown'];
    stateOrder.forEach((state) => {
      const prs = groupedByState.get(state);
      if (prs && prs.length > 0) {
        console.log(`${state.toUpperCase()} (${prs.length}):`);
        console.log('─'.repeat(75));

        prs.forEach((item) => {
          const prDetails: PRDetails | undefined = item.pr ? {
            state: item.pr.state,
            draft: item.pr.draft || false,
            // Use merged_at to determine if PR is merged (list endpoint doesn't return 'merged' field reliably)
            merged: item.pr.merged_at !== null && item.pr.merged_at !== undefined,
          } : undefined;

          console.log(formatNotificationCompact(item.notification, item.prNumber, prDetails));
        });
      }
    });
  }
}

function extractPRNumber(url: string | null): number {
  if (!url) return 0;
  const match = url.match(/\/pulls\/(\d+)$/);
  return match ? parseInt(match[1], 10) : 0;
}

function extractWorkflowRunId(url: string | null): number {
  if (!url) return 0;
  const match = url.match(/\/runs\/(\d+)$/);
  return match ? parseInt(match[1], 10) : 0;
}

async function fetchPullRequestDetails(
  octokit: any,
  owner: string,
  repo: string,
  notifications: any[],
): Promise<PRNotificationWithDetails[]> {
  const prNumbers = notifications
    .map((n) => extractPRNumber(n.subject.url))
    .filter((n) => n > 0);

  const prMap = new Map<number, any>();

  if (prNumbers.length < 50) {
    // Fetch individually for small numbers
    console.log(`Fetching ${prNumbers.length} PRs individually...`);
    await Promise.all(
      prNumbers.map(async (prNumber) => {
        try {
          const { data: pr } = await octokit.pulls.get({
            owner,
            repo,
            pull_number: prNumber,
          });
          prMap.set(prNumber, pr);
        } catch (error) {
          console.error(`Failed to fetch PR #${prNumber}`);
        }
      }),
    );
  } else {
    // Fetch all PRs and lookup
    console.log('Fetching all PRs from repository (optimized for large count)...');
    const allPrs = await octokit.paginate(
      octokit.pulls.list,
      {
        owner, repo, state: 'all', per_page: 100,
      },
    );

    const prNumbersSet = new Set(prNumbers);
    allPrs.forEach((pr: any) => {
      if (prNumbersSet.has(pr.number)) {
        prMap.set(pr.number, pr);
      }
    });
  }

  // Build result array with notifications and their PR details
  return notifications.map((notification) => {
    const prNumber = extractPRNumber(notification.subject.url);
    return {
      notification,
      prNumber,
      pr: prMap.get(prNumber),
    };
  });
}

async function fetchWorkflowRunDetails(
  octokit: any,
  owner: string,
  repo: string,
  notifications: any[],
): Promise<WorkflowRunNotificationWithDetails[]> {
  // Separate notifications with valid URLs from those without
  const notificationsWithUrls = notifications.filter((n) => n.subject.url);
  const notificationsWithoutUrls = notifications.filter((n) => !n.subject.url);

  if (notificationsWithoutUrls.length > 0) {
    console.log(`Note: ${notificationsWithoutUrls.length} workflow run notification(s) have no URL and cannot be fetched.\n`);
  }

  const runIds = notificationsWithUrls
    .map((n) => extractWorkflowRunId(n.subject.url))
    .filter((n) => n > 0);

  const runMap = new Map<number, any>();

  if (runIds.length > 0) {
    console.log(`Fetching ${runIds.length} workflow runs individually...`);
    await Promise.all(
      runIds.map(async (runId) => {
        try {
          const { data: run } = await octokit.actions.getWorkflowRun({
            owner,
            repo,
            run_id: runId,
          });
          runMap.set(runId, run);
        } catch (error) {
          console.error(`Failed to fetch workflow run #${runId}`);
        }
      }),
    );
  }

  // Build result array with notifications and their workflow run details
  return notifications.map((notification) => {
    const runId = extractWorkflowRunId(notification.subject.url);
    return {
      notification,
      runId,
      run: runMap.get(runId),
    };
  });
}
