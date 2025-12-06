import TVLCard from "./tvl-card";
import ChartContent from "./chart-content";
import Description from "./description";
import StakeContent from "./stake-content";

export default function QQBContent() {
  return (
    <section className="w-full py-6 lg:py-10">
      <div className="mx-auto max-w-6xl">
        <div className="grid gap-6 lg:grid-cols-[minmax(0,2fr)_minmax(320px,1.2fr)]">
          
          <div className="flex flex-col gap-6">
            <TVLCard />
            <ChartContent />
          </div>

         
          <div className="flex flex-col gap-6">
            <Description />
            <StakeContent />
          </div>
        </div>
      </div>
    </section>
  );
}
