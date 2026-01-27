import { getOctokit } from './utils';

interface RepoNotificationCount {
  repo: string;
  unread: number;
  read: number;
  total: number;
}

export async function listRepos(options?: { all?: boolean }): Promise<void> {
  const octokit = getOctokit();

  console.log('Fetching notifications...\n');

  // Fetch all notifications with pagination
  let allNotifications = await octokit.paginate(
    octokit.activity.listNotificationsForAuthenticatedUser,
    { all: true, per_page: 100 },
  );

  // By default, only show unread notifications unless --all is specified
  if (!options?.all) {
    allNotifications = allNotifications.filter((n) => n.unread);
  }

  // Group by repository
  const repoMap = new Map<string, RepoNotificationCount>();

  allNotifications.forEach((notification) => {
    const repoName = notification.repository.full_name;

    if (!repoMap.has(repoName)) {
      repoMap.set(repoName, {
        repo: repoName,
        unread: 0,
        read: 0,
        total: 0,
      });
    }

    const stats = repoMap.get(repoName)!;
    stats.total += 1;

    if (notification.unread) {
      stats.unread += 1;
    } else {
      stats.read += 1;
    }
  });

  // Sort by total notifications (descending)
  const repos = Array.from(repoMap.values()).sort((a, b) => b.total - a.total);

  if (repos.length === 0) {
    console.log('No notifications found.');
    return;
  }

  console.log('Repositories with notifications:\n');
  console.log(
    'Repository                                    Unread  Read   Total',
  );
  console.log('─'.repeat(75));

  repos.forEach((repo) => {
    const repoName = repo.repo.padEnd(45);
    const unread = String(repo.unread).padStart(6);
    const read = String(repo.read).padStart(6);
    const total = String(repo.total).padStart(6);

    console.log(`${repoName}${unread}${read}${total}`);
  });

  console.log('─'.repeat(75));
  const totalUnread = repos.reduce((sum, r) => sum + r.unread, 0);
  const totalRead = repos.reduce((sum, r) => sum + r.read, 0);
  const totalAll = repos.reduce((sum, r) => sum + r.total, 0);

  console.log(
    `${'TOTAL'.padEnd(45)}${String(totalUnread).padStart(6)}${String(
      totalRead,
    ).padStart(6)}${String(totalAll).padStart(6)}`,
  );
  console.log('');
}
