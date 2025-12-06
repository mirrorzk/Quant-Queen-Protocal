"use client";

import { useMemo, useState } from "react";
import {
  AreaChart,
  Area,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
} from "recharts";

type RangeKey = "1M" | "3M" | "ALL";

const rawData = [
    { label: "Sep 2022", nav: 1 },
    { label: "Oct 2022", nav: 1.1468 },
    { label: "Nov 2022", nav: 1.09393252 },
    { label: "Dec 2022", nav: 1.157489999 },
  
    { label: "Jan 2023", nav: 1.250667944 },
    { label: "Feb 2023", nav: 1.613111515 },
    { label: "Mar 2023", nav: 1.827977968 },
    { label: "Apr 2023", nav: 1.902193874 },
    { label: "May 2023", nav: 1.956977057 },
    { label: "Jun 2023", nav: 2.107272895 },
    { label: "Jul 2023", nav: 2.376582372 },
    { label: "Aug 2023", nav: 2.166730148 },
    { label: "Sep 2023", nav: 2.148096269 },
    { label: "Oct 2023", nav: 2.423482211 },
    { label: "Nov 2023", nav: 2.684006548 },
    { label: "Dec 2023", nav: 3.309111673 },
  
    { label: "Jan 2024", nav: 3.77304913 },
    { label: "Feb 2024", nav: 4.286561116 },
    { label: "Mar 2024", nav: 4.831383034 },
    { label: "Apr 2024", nav: 5.161849634 },
    { label: "May 2024", nav: 5.303800499 },
    { label: "Jun 2024", nav: 5.792280525 },
    { label: "Jul 2024", nav: 5.930136801 },
    { label: "Aug 2024", nav: 5.988252142 },
    { label: "Sep 2024", nav: 6.58528088 },
    { label: "Oct 2024", nav: 6.670889532 },
    { label: "Nov 2024", nav: 7.191886004 },
    { label: "Dec 2024", nav: 7.903882719 },
  
    { label: "Jan 2025", nav: 9.782635641 },
    { label: "Feb 2025", nav: 10.02328848 },
    { label: "Mar 2025", nav: 10.50741331 },
    { label: "Apr 2025", nav: 11.93747226 },
    { label: "May 2025", nav: 13.30789408 },
    { label: "Jun 2025", nav: 13.31454803 },
    { label: "Jul 2025", nav: 14.00690452 },
    { label: "Aug 2025", nav: 14.04892524 },
    { label: "Sep 2025", nav: 15.58868744 },
    { label: "Oct 2025", nav: 17.53727337 },
  ];
  

// 根据范围筛数据：这里只是大概示例
function filterByRange(range: RangeKey) {
  if (range === "ALL") return rawData;
  if (range === "3M") return rawData.slice(-12); // 最近 12 个点
  return rawData.slice(-4); // 1M: 最近 4 个点
}

// 自定义 Tooltip
function CustomTooltip({ active, payload }: any) {
  if (!active || !payload?.length) return null;
  const item = payload[0].payload as (typeof rawData)[number];
  const [month, year] = item.label.split(" ");

  return (
    <div className="rounded-xl bg-white/95 px-3 py-2 text-xs shadow-md ring-1 ring-slate-200">
      <div className="font-semibold text-slate-700">
        {month} {year}
      </div>
      <div className="mt-1 text-[11px] uppercase tracking-[0.18em] text-slate-400">
        NAV
      </div>
      <div className="text-sm font-semibold text-[#1C76D9]">
        {item.nav.toFixed(2)}
      </div>
    </div>
  );
}

// 自定义 X 轴刻度：只在每年首次出现（通常 Jan）显示 (2024)
const CustomXAxisTick = ({ x, y, payload, index, data }: any) => {
  const [month, year] = String(payload.value).split(" ");

  let showYear = false;
  if (index === 0) {
    showYear = true;
  } else {
    const prev = data[index - 1].label as string;
    const [, prevYear] = prev.split(" ");
    showYear = prevYear !== year; // 年份变化 -> 显示
  }

  return (
    <g transform={`translate(${x},${y})`}>
      {/* 月份 */}
      <text
        x={0}
        y={10}
        textAnchor="middle"
        fill="#4B5563"
        fontSize={12}
        fontWeight={500}
      >
        {month}
      </text>

      {/* 年份，仅在该年第一次出现时显示 */}
      {showYear && (
        <text
          x={0}
          y={26}
          textAnchor="middle"
          fill="#94A3B8"
          fontSize={10}
          fontWeight={400}
        >
          ({year})
        </text>
      )}
    </g>
  );
};

export default function ChartContent() {
  const [range, setRange] = useState<RangeKey>("1M");

  const data = useMemo(() => filterByRange(range), [range]);

  return (
    <div className="w-full rounded-3xl border border-[#C8C8C8] bg-white px-4 pb-6 pt-5 shadow-[0_18px_45px_rgba(15,23,42,0.08)] sm:px-6 sm:pb-7 sm:pt-6">
      <div className="mb-4 flex items-center justify-between sm:mb-5">
        <h2 className="text-lg font-semibold tracking-[0.18em] text-[#1D5FB5] sm:text-xl">
          QQB NAV
        </h2>

        <div className="flex items-center gap-4 text-xs font-medium sm:text-sm">
          {(["1M", "3M", "ALL"] as RangeKey[]).map((key) => (
            <button
              key={key}
              onClick={() => setRange(key)}
              className={`uppercase tracking-[0.18em] ${
                range === key
                  ? "text-[#1D5FB5]"
                  : "text-slate-400 hover:text-slate-600"
              }`}
            >
              {key}
            </button>
          ))}
        </div>
      </div>

      {/* 图表区域 */}
      <div className="h-[260px] w-full sm:h-[16vw]">
        <ResponsiveContainer width="100%" height="100%">
          <AreaChart
            data={data}
            margin={{ top: 10, right: 20, left: 20, bottom: 30 }}
          >
            {/* 网格线 */}
            <CartesianGrid
              stroke="#E2E8F0"
              strokeDasharray="0"
              vertical={true}
              horizontal={true}
            />

            {/* X 轴：月份 + (年份) */}
            <XAxis
              dataKey="label"
              tickLine={false}
              axisLine={false}
              tickMargin={12}
              tick={(props) => <CustomXAxisTick {...props} data={data} />}
            />

            {/* Y 轴：数值 */}
            <YAxis
              tickLine={false}
              axisLine={false}
              ticks={[1, 5, 10, 15, 20]}
              domain={[1, 20]}
              tick={{ fill: "#6B7280", fontSize: 11 }}
            />

            <Tooltip content={<CustomTooltip />} />

            {/* 渐变填充 */}
            <defs>
              <linearGradient id="navArea" x1="0" y1="0" x2="0" y2="1">
                <stop offset="0%" stopColor="#1C76D9" stopOpacity={0.35} />
                <stop offset="100%" stopColor="#1C76D9" stopOpacity={0.02} />
              </linearGradient>
            </defs>

            {/* 折线 + 面积：type="linear" -> 折线，不平滑 */}
            <Area
              type="linear"
              dataKey="nav"
              stroke="#1C76D9"
              strokeWidth={3}
              fill="url(#navArea)"
              activeDot={{ r: 4 }}
            />
          </AreaChart>
        </ResponsiveContainer>
      </div>
    </div>
  );
}
