import { Octokit } from '@octokit/rest';

export function getOctokit(): Octokit {
  const token = process.env.GITHUB_TOKEN;

  if (!token) {
    console.error('Error: GITHUB_TOKEN environment variable is not set');
    console.error('Please set your GitHub personal access token:');
    console.error('  export GITHUB_TOKEN=your_token_here');
    process.exit(1);
  }

  return new Octokit({ auth: token });
}

export interface PRDetails {
  state: 'open' | 'closed';
  draft: boolean;
  merged: boolean;
}

export function formatNotificationCompact(
  notification: any,
  prNumber?: number,
  prDetails?: PRDetails,
): string {
  const unreadMark = notification.unread ? '●' : '○';
  const { type } = notification.subject;
  const reason = `[${notification.reason}]`;

  let subject = notification.subject.title;

  // Add PR number and details if it's a pull request
  if (type === 'PullRequest' && prNumber) {
    const flags: string[] = [];

    if (prDetails) {
      flags.push(prDetails.state);
      if (prDetails.draft) flags.push('draft');
      if (prDetails.merged) flags.push('merged');
    }

    const flagsStr = flags.length > 0 ? ` [${flags.join(', ')}]` : '';
    subject = `#${prNumber}${flagsStr} ${subject}`;
  }

  return `${unreadMark} [${type}] ${reason} ${subject}`;
}
