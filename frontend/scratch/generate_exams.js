const fs = require('fs');
const path = require('path');

const targetPath = 'c:/Users/rinku/OneDrive/Desktop/KVM/schoolmgnt/frontend/assets/data/examinations/examinations.json';

const months = [
  { name: 'August 2025', key: '2025-08', code: 'aug', startDay: '2025-08-20', endDay: '2025-08-26', rank: 22 },
  { name: 'July 2025', key: '2025-07', code: 'jul', startDay: '2025-07-20', endDay: '2025-07-26', rank: 25 },
  { name: 'June 2025', key: '2025-06', code: 'jun', startDay: '2025-06-20', endDay: '2025-06-26', rank: 28 },
  { name: 'May 2025', key: '2025-05', code: 'may', startDay: '2025-05-22', endDay: '2025-05-28', rank: 31 },
  { name: 'April 2025', key: '2025-04', code: 'apr', startDay: '2025-04-20', endDay: '2025-04-26', rank: 35 }
];

const subjects = [
  { name: 'Bangla', time: '09:30 AM - 11:30 AM', start: '09:30 AM', end: '11:30 AM' },
  { name: 'Chemistry', time: '09:30 AM - 11:30 AM', start: '09:30 AM', end: '11:30 AM' },
  { name: 'English', time: '09:30 AM - 11:30 AM', start: '09:30 AM', end: '11:30 AM' },
  { name: 'ICT', time: '10:00 AM - 12:00 PM', start: '10:00 AM', end: '12:00 PM' },
  { name: 'Mathematics', time: '09:30 AM - 11:30 AM', start: '09:30 AM', end: '11:30 AM' },
  { name: 'Physics', time: '09:30 AM - 11:30 AM', start: '09:30 AM', end: '11:30 AM' }
];

function getGrade(score) {
  if (score >= 80) return 'A+';
  if (score >= 70) return 'A';
  if (score >= 60) return 'B+';
  if (score >= 50) return 'B';
  if (score >= 40) return 'C';
  return 'D';
}

const schedules = [];
const papers = [];

// Base score profile per subject: [April, May, June, July, August] - showing natural academic improvement
const subjectProgress = {
  Bangla:      [74, 78, 82, 85, 88],
  Chemistry:   [46, 50, 52, 58, 62],
  English:     [58, 62, 64, 68, 72],
  ICT:         [66, 70, 72, 76, 80],
  Mathematics: [70, 75, 78, 82, 85],
  Physics:     [56, 60, 64, 68, 72]
};

// 1. Generate Monthly Test Schedules & Papers
months.forEach((m, mIdx) => {
  // mIdx: 0=August, 1=July, 2=June, 3=May, 4=April
  // Invert index for progress (April=0, May=1, June=2, July=3, August=4)
  const progIdx = 4 - mIdx;
  const schId = `monthly-${m.code}-2025`;
  
  let totalObtained = 0;
  const schPapers = [];

  subjects.forEach((sub, sIdx) => {
    const baseScore = subjectProgress[sub.name][progIdx];
    const score = baseScore; // Clean integers
    totalObtained += score;

    const dayNum = 20 + sIdx;
    const monthShort = m.name.split(' ')[0].substring(0, 3);
    const examDate = `${dayNum} ${monthShort} 2025`;

    schPapers.push({
      id: `ep-m-${m.code}25-${sub.name.toLowerCase()}`,
      exam_schedule_id: schId,
      subject: sub.name,
      exam_date: examDate,
      start_time: sub.start,
      end_time: sub.end,
      time_slot: sub.time,
      max_marks: 100.0,
      min_marks: 35.0,
      marks_obtained: score * 1.0,
      grade: getGrade(score),
      result: 'Pass'
    });
  });

  const avg = totalObtained / 6;

  schedules.push({
    id: schId,
    title: `Monthly Test (${m.name.split(' ')[0].substring(0, 3)}-2025)`,
    test_type: 'MONTHLY',
    month: m.name,
    month_key: m.key,
    academic_year: '2026-2027',
    status: 'COMPLETED',
    description: `Comprehensive Monthly Assessment for ${m.name} evaluating core subjects.`,
    start_date: m.startDay,
    end_date: m.endDay,
    rank: m.rank,
    total_max: 600.0,
    total_obtained: totalObtained * 1.0,
    overall_grade: getGrade(avg),
    overall_result: 'Pass',
    created_at: `2025-${m.key.split('-')[1]}-01T09:00:00.000Z`,
    updated_at: `2025-${m.key.split('-')[1]}-28T09:00:00.000Z`
  });

  papers.push(...schPapers);
});

// 2. Generate Weekly Test Schedules & Papers (All 4 Weeks for each of the 5 Months)
const weekConfigs = [
  { week: 1, startDay: 2, endDay: 8, label: 'Week 1', rankOffset: 6, scoreDelta: -8 },
  { week: 2, startDay: 9, endDay: 15, label: 'Week 2', rankOffset: 4, scoreDelta: -4 },
  { week: 3, startDay: 16, endDay: 22, label: 'Week 3', rankOffset: 2, scoreDelta: 0 },
  { week: 4, startDay: 23, endDay: 29, label: 'Week 4', rankOffset: 0, scoreDelta: 4 }
];

months.forEach((m, mIdx) => {
  const progIdx = 4 - mIdx; // April=0 ... August=4
  const monthShort = m.name.split(' ')[0].substring(0, 3);
  const monthNum = m.key.split('-')[1];

  weekConfigs.forEach((wc) => {
    const schId = `weekly-${m.code}-2025-w${wc.week}`;
    let totalObtained = 0;
    const schPapers = [];

    subjects.forEach((sub, sIdx) => {
      const baseScore = subjectProgress[sub.name][progIdx];
      // Slight variation per week
      let score = baseScore + Math.floor(wc.scoreDelta / 2) + ((sIdx % 2 === 0) ? 1 : -1);
      if (score > 98) score = 98;
      if (score < 40) score = 40;
      totalObtained += score;

      const day = wc.startDay + sIdx;
      const dayFormatted = day < 10 ? `0${day}` : `${day}`;
      const examDate = `${dayFormatted} ${monthShort} 2025`;

      schPapers.push({
        id: `ep-w-${m.code}25-w${wc.week}-${sub.name.toLowerCase()}`,
        exam_schedule_id: schId,
        subject: sub.name,
        exam_date: examDate,
        start_time: '08:30 AM',
        end_time: '10:00 AM',
        time_slot: '08:30 AM - 10:00 AM',
        max_marks: 100.0,
        min_marks: 35.0,
        marks_obtained: score * 1.0,
        grade: getGrade(score),
        result: 'Pass'
      });
    });

    const avg = totalObtained / 6;
    const rank = m.rank + wc.rankOffset;
    const sDay = wc.startDay < 10 ? `0${wc.startDay}` : `${wc.startDay}`;
    const eDay = wc.endDay < 10 ? `0${wc.endDay}` : `${wc.endDay}`;

    schedules.push({
      id: schId,
      title: `Weekly Test (${monthShort}-2025 W${wc.week})`,
      test_type: 'WEEKLY',
      month: m.name,
      month_key: m.key,
      week: wc.week,
      week_label: wc.label,
      academic_year: '2026-2027',
      status: 'COMPLETED',
      description: `Weekly continuous evaluation test for ${monthShort} ${wc.label}.`,
      start_date: `2025-${monthNum}-${sDay}`,
      end_date: `2025-${monthNum}-${eDay}`,
      rank: rank,
      total_max: 600.0,
      total_obtained: totalObtained * 1.0,
      overall_grade: getGrade(avg),
      overall_result: 'Pass',
      created_at: `2025-${monthNum}-${sDay}T08:00:00.000Z`,
      updated_at: `2025-${monthNum}-${eDay}T16:00:00.000Z`
    });

    papers.push(...schPapers);
  });
});

const finalData = {
  exam_schedules: schedules,
  exam_papers: papers
};

fs.writeFileSync(targetPath, JSON.stringify(finalData, null, 2), 'utf-8');
console.log(`Successfully written ${schedules.length} schedules and ${papers.length} papers to ${targetPath}`);
