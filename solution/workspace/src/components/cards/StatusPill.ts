export type SystemStatus = "healthy" | "degraded" | "offline";

export type StatusPillProps = {
  status: SystemStatus;
};

export function StatusPill(props: StatusPillProps): string {
  return `<span data-status="${props.status}">${props.status.toUpperCase()}</span>`;
}
