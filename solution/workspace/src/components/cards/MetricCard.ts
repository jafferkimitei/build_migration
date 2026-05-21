export type MetricTrend = "up" | "flat" | "down";

export type MetricCardProps = {
  label: string;
  value: string;
  trend: MetricTrend;
};

export function MetricCard(props: MetricCardProps): string {
  return `<section data-trend="${props.trend}"><strong>${props.label}</strong><span>${props.value}</span></section>`;
}
