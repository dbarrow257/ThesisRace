#include "TLegend.h"
#include "TGraph.h"
#include "TGaxis.h"
#include "TH2.h"
#include "TPad.h"
#include "TStyle.h"
#include "TROOT.h"

#include <fstream>
#include <iostream>
using namespace std;

const int colors[] = {kBlue, kMagenta, kRed, kBlack, 38, 46, kViolet-8, 30, kPink+1};

TGraph* thesis_count_graph(const char* name, bool offset)
{
  ifstream in(Form("thesiscount_%s.txt", name));

  TGraph* g = new TGraph;

  string date;
  int words;
  int secs;

  int counter=0;
  double firstCommit;
  while(in >> date >> words >> secs){
    //cout << date << " " << words << " " << secs << endl;
    g->SetPoint(counter, secs, double(words)/1000);
    if(counter==0) firstCommit=secs;
    if(offset){
      // For the offset graph, the x axis will be "days since start",
      // so rescale accordingly
      g->SetPoint(counter, (secs-firstCommit)/(24*60*60), double(words)/1000);
    }
    ++counter;
  }

  return g;
}

void plot_thesis_count(bool offset)
{
  gROOT->SetBatch(true);
  gStyle->SetOptStat(false);
  gStyle->SetTimeOffset(0);

  const int nNames=8;
  const char* names[nNames] = { "Dan", "kirsty", "tom", "abbey", "phil", "gemma", "justin", "phill" };
  const char* upperNames[nNames] = { "Dan", "Kirsty", "Tom", "Abbey", "Phil", "Gemma", "Justin", "Phill" };
  vector<TGraph*> graphs;
  for(int i=0; i< (offset ? nNames : nNames-3); ++i)
    graphs.push_back(thesis_count_graph(names[i], offset));


  double xmin, xmax, ymin, ymax;

  graphs[0]->GetPoint(0, xmin, ymin);
  graphs[0]->GetPoint(graphs[0]->GetN()-1, xmax, ymax);

  // Initial index is 1 because we already did the zeroth entry
  for(int i=1; i<(int)graphs.size(); ++i){
    double xminthis, xmaxthis, yminthis, ymaxthis;
    TGraph* g=graphs[i];
    g->GetPoint(0, xminthis, yminthis);
    g->GetPoint(g->GetN()-1, xmaxthis, ymaxthis);
    if(xminthis<xmin) xmin=xminthis;
    if(yminthis<ymin) ymin=yminthis;
    if(xmaxthis>xmax) xmax=xmaxthis;
    if(ymaxthis>ymax) ymax=ymaxthis;
  }

  // Give it a week either way
  xmin -= offset ? 7 : 7*24*60*60;
  xmax += offset ? 7 : 7*24*60*60;
  // And some space above
  ymax *= 1.1;

  // Don't use scientific notation
  TGaxis::SetMaxDigits(100);

  TH1* axes;
  if(offset)
    axes= new TH2I("",";Days since start;Thousands of Words",
                   100, xmin, xmax, 100, 0, ymax);
  else{
    axes= new TH2I("",";Date;Thousands of Words",
                   100, xmin, xmax, 100, 0, ymax);
    axes->GetXaxis()->SetTimeDisplay(1);
    axes->GetXaxis()->SetTimeFormat("%d %b %y");
  }

  // This only works for explicit textual labels, because the root developers are lazy
  //axes->GetXaxis()->LabelsOption("v");
  axes->Draw();

  for(int i = int(graphs.size()-1); i >= 0; --i){
    TGraph* g=graphs[i];
    g->SetLineColor(colors[i]);
    g->SetLineWidth(2);
    g->Draw("l");

    // Doesn't seem to get a good fit
    //    g->Fit("pol1");
  }

  TLegend* leg=new TLegend(0.15, 0.6, 0.3, 0.88);
  leg->SetBorderSize(0);
  leg->SetFillStyle(0);
  for(int i=0; i<(int)graphs.size(); ++i)
    leg->AddEntry(graphs[i], upperNames[i], "l");
  leg->Draw();

  gPad->Print(offset ? "thesis_count_offset.png" :
                       "thesis_count.png");
}

void plot_thesis_count()
{
  plot_thesis_count(false);
  plot_thesis_count(true);
}
