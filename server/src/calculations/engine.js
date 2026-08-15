/**
 * BILLEL ATTENDANCE — Calculation Engine & Anomaly Detector
 * Simplified attendance details & presence breakdown (No Overtime calculation)
 */

const FRENCH_DAYS = [
  'Dimanche',
  'Lundi',
  'Mardi',
  'Mercredi',
  'Jeudi',
  'Vendredi',
  'Samedi'
];

/**
 * Convert Date or String to HH:mm string
 */
function toHHMM(date) {
  if (!date) return '--:--';
  const d = new Date(date);
  if (isNaN(d.getTime())) return '--:--';
  const h = String(d.getHours()).padStart(2, '0');
  const m = String(d.getMinutes()).padStart(2, '0');
  return `${h}:${m}`;
}

/**
 * Convert minutes number to "XXhYY" string
 */
function formatMinutesToHours(minutes, separator = 'h') {
  if (minutes === null || minutes === undefined || isNaN(minutes) || minutes < 0) {
    return `00${separator}00`;
  }
  const hrs = Math.floor(minutes / 60);
  const mins = Math.floor(minutes % 60);
  return `${String(hrs).padStart(2, '0')}${separator}${String(mins).padStart(2, '0')}`;
}

/**
 * Parse "HH:mm" to minutes from 00:00
 */
function parseTimeToMinutes(timeStr) {
  if (!timeStr || typeof timeStr !== 'string') return 0;
  const parts = timeStr.split(':');
  const h = parseInt(parts[0], 10) || 0;
  const m = parseInt(parts[1], 10) || 0;
  return h * 60 + m;
}

/**
 * Format a Date to YYYY-MM-DD
 */
function formatDateKey(d) {
  const year = d.getFullYear();
  const month = String(d.getMonth() + 1).padStart(2, '0');
  const day = String(d.getDate()).padStart(2, '0');
  return `${year}-${month}-${day}`;
}

/**
 * Format YYYY-MM-DD to DD/MM/YYYY
 */
function formatDateFR(dateStr) {
  if (!dateStr) return '';
  const parts = dateStr.split('-');
  if (parts.length === 3) {
    return `${parts[2]}/${parts[1]}/${parts[0]}`;
  }
  const d = new Date(dateStr);
  if (isNaN(d.getTime())) return dateStr;
  const day = String(d.getDate()).padStart(2, '0');
  const month = String(d.getMonth() + 1).padStart(2, '0');
  const year = d.getFullYear();
  return `${day}/${month}/${year}`;
}

/**
 * Core calculation function for a single day's punches
 */
function calculateDayAttendance(dateKey, rawPunches = [], options = {}) {
  const {
    standardStartTime = '08:00',
    duplicateWindowSec = 120,
    referenceDate = new Date()
  } = options;

  const dateObj = new Date(`${dateKey}T00:00:00`);
  const dayOfWeekIndex = dateObj.getDay();
  const dayNameFR = FRENCH_DAYS[dayOfWeekIndex];
  const dateFormattedFR = formatDateFR(dateKey);
  const isWeekend = dayOfWeekIndex === 5 || dayOfWeekIndex === 6; // Friday & Saturday

  // Determine date timing relative to today
  const todayStr = formatDateKey(new Date(referenceDate));
  const isFuture = dateKey > todayStr;
  const isToday = dateKey === todayStr;
  const isPast = dateKey < todayStr;

  const result = {
    date: dateKey,
    dateFR: dateFormattedFR,
    dayName: dayNameFR,
    dayOfWeek: dayOfWeekIndex,
    isWeekend,
    isFuture,
    isToday,
    isPast,
    
    // RAW source fields (untouched)
    rawPunches: [...rawPunches],
    rawEntry: null,
    rawExit: null,
    
    // Display times
    entryTime: '--:--',
    exitTime: '--:--',
    
    // Calculated durations in minutes
    workTimeMinutes: 0,
    delayMinutes: 0,
    earlyExitMinutes: 0,
    
    // Formatted duration strings
    workTimeStr: '00h00',
    delayStr: '00h00',
    earlyExitStr: '00h00',
    
    // Status & Anomalies
    status: isFuture ? 'À venir' : 'Absence',
    statusBadge: isFuture ? 'badge-muted' : 'badge-danger',
    anomalies: []
  };

  // 1. If no punches recorded
  if (!rawPunches || rawPunches.length === 0) {
    if (isWeekend) {
      result.status = 'Repos / Week-end';
      result.statusBadge = 'badge-muted';
    } else if (isFuture) {
      result.status = 'À venir';
      result.statusBadge = 'badge-muted';
      // No anomalies for future dates!
    } else if (isToday) {
      result.status = 'En attente (Aujourd\'hui)';
      result.statusBadge = 'badge-muted';
    } else {
      // Past working day with no punch = Confirmed Absence
      result.status = 'Absence';
      result.statusBadge = 'badge-danger';
      result.anomalies.push({
        code: 'ABSENCE',
        label: 'Absence constatée',
        severity: 'warning'
      });
    }
    return result;
  }

  // 2. Sort punches chronologically
  const sortedPunches = [...rawPunches].sort((a, b) => new Date(a.punchTime) - new Date(b.punchTime));

  // Check for duplicate punches
  const cleanPunches = [];
  for (let i = 0; i < sortedPunches.length; i++) {
    const current = sortedPunches[i];
    const prev = cleanPunches[cleanPunches.length - 1];

    if (prev) {
      const diffSec = Math.abs((new Date(current.punchTime) - new Date(prev.punchTime)) / 1000);
      if (diffSec <= duplicateWindowSec) {
        result.anomalies.push({
          code: 'DUPLICATE_PUNCH',
          label: `Pointage en doublon (${toHHMM(current.punchTime)} ignoré)`,
          severity: 'info',
          time: current.punchTime
        });
        continue;
      }
    }
    cleanPunches.push(current);
  }

  // 3. Evaluate Single Punch Case
  if (cleanPunches.length === 1) {
    const singlePunch = cleanPunches[0];
    const punchHour = new Date(singlePunch.punchTime).getHours();
    
    // If today and only 1 punch recorded, the employee is currently present at work
    if (isToday) {
      result.rawEntry = singlePunch;
      result.entryTime = toHHMM(singlePunch.punchTime);
      result.status = 'Présent (En cours)';
      result.statusBadge = 'badge-info';
      
      const entryDate = new Date(singlePunch.punchTime);
      const stdStartMinutes = parseTimeToMinutes(standardStartTime);
      const entryMinutesOfDay = entryDate.getHours() * 60 + entryDate.getMinutes();

      if (entryMinutesOfDay > stdStartMinutes) {
        result.delayMinutes = entryMinutesOfDay - stdStartMinutes;
        result.delayStr = formatMinutesToHours(result.delayMinutes);
      }
      return result;
    }

    // Past date single punch: Incomplete
    if (punchHour < 13) {
      result.rawEntry = singlePunch;
      result.entryTime = toHHMM(singlePunch.punchTime);
      result.status = 'Pointage incomplet';
      result.statusBadge = 'badge-warning';
      result.anomalies.push({
        code: 'NO_EXIT',
        label: 'Sortie manquante (Pointage incomplet)',
        severity: 'danger'
      });
    } else {
      result.rawExit = singlePunch;
      result.exitTime = toHHMM(singlePunch.punchTime);
      result.status = 'Pointage incomplet';
      result.statusBadge = 'badge-warning';
      result.anomalies.push({
        code: 'NO_ENTRY',
        label: 'Entrée manquante (Pointage incomplet)',
        severity: 'danger'
      });
    }
    return result;
  }

  // 4. Normal / Multi-punch processing
  const firstPunch = cleanPunches[0];
  const lastPunch = cleanPunches[cleanPunches.length - 1];

  result.rawEntry = firstPunch;
  result.rawExit = lastPunch;
  result.entryTime = toHHMM(firstPunch.punchTime);
  result.exitTime = toHHMM(lastPunch.punchTime);

  const entryDate = new Date(firstPunch.punchTime);
  const exitDate = new Date(lastPunch.punchTime);
  
  let rawDurationMinutes = Math.floor((exitDate.getTime() - entryDate.getTime()) / (1000 * 60));

  if (rawDurationMinutes < 0) {
    result.status = 'Anomalie';
    result.statusBadge = 'badge-danger';
    result.anomalies.push({
      code: 'NEGATIVE_DURATION',
      label: 'Heure de sortie antérieure à l\'entrée',
      severity: 'danger'
    });
    return result;
  }

  if (rawDurationMinutes === 0) {
    if (isToday) {
      result.status = 'Présent (En cours)';
      result.statusBadge = 'badge-info';
    } else {
      result.status = 'Pointage incomplet';
      result.statusBadge = 'badge-warning';
      result.anomalies.push({
        code: 'ZERO_DURATION',
        label: 'Durée de présence nulle (00:00)',
        severity: 'warning'
      });
    }
    return result;
  }

  result.workTimeMinutes = rawDurationMinutes;

  // Delay (Retard) Calculation (Standard: 08:00)
  const stdStartMinutes = parseTimeToMinutes(standardStartTime);
  const entryMinutesOfDay = entryDate.getHours() * 60 + entryDate.getMinutes();

  if (entryMinutesOfDay > stdStartMinutes) {
    result.delayMinutes = entryMinutesOfDay - stdStartMinutes;
  } else {
    result.delayMinutes = 0;
  }

  // Format strings
  result.workTimeStr = formatMinutesToHours(result.workTimeMinutes);
  result.delayStr = formatMinutesToHours(result.delayMinutes);
  result.earlyExitStr = formatMinutesToHours(result.earlyExitMinutes);

  // Status determination
  if (result.anomalies.length > 0) {
    result.status = 'Pointage avec anomalie';
    result.statusBadge = 'badge-warning';
  } else if (result.delayMinutes > 0) {
    result.status = 'Présent (Retard)';
    result.statusBadge = 'badge-warning';
  } else {
    result.status = 'Présent';
    result.statusBadge = 'badge-success';
  }

  return result;
}

/**
 * Process a full date range of punches for an employee
 */
function processAttendanceRange(startDateStr, endDateStr, rawTransactions = [], options = {}) {
  const punchesByDate = {};
  
  const start = new Date(`${startDateStr}T00:00:00`);
  const end = new Date(`${endDateStr}T00:00:00`);
  
  const current = new Date(start);
  while (current <= end) {
    const key = formatDateKey(current);
    punchesByDate[key] = [];
    current.setDate(current.getDate() + 1);
  }

  rawTransactions.forEach(t => {
    if (!t.punchTime) return;
    const dateKey = t.punchTime.split(' ')[0] || t.punchTime.split('T')[0];
    if (punchesByDate[dateKey]) {
      punchesByDate[dateKey].push(t);
    } else {
      punchesByDate[dateKey] = [t];
    }
  });

  const todayStr = formatDateKey(new Date(options.referenceDate || new Date()));

  const days = [];
  let totalWorkedMinutes = 0;
  let totalDelayMinutes = 0;
  let daysWorked = 0;
  let totalDelaysCount = 0;
  let totalAbsencesCount = 0;
  let totalAnomaliesCount = 0;
  let elapsedWorkingDaysCount = 0;

  const sortedDateKeys = Object.keys(punchesByDate).sort();

  for (const dateKey of sortedDateKeys) {
    const dayResult = calculateDayAttendance(dateKey, punchesByDate[dateKey], options);
    days.push(dayResult);

    const isPastOrToday = dateKey <= todayStr;
    const isWorkingDay = !dayResult.isWeekend;

    if (isPastOrToday && isWorkingDay) {
      elapsedWorkingDaysCount++;
    }

    if (dayResult.workTimeMinutes > 0 || (dayResult.isToday && dayResult.rawEntry)) {
      daysWorked++;
      totalWorkedMinutes += dayResult.workTimeMinutes;
    }
    if (dayResult.delayMinutes > 0) {
      totalDelaysCount++;
      totalDelayMinutes += dayResult.delayMinutes;
    }
    if (dayResult.status === 'Absence') {
      totalAbsencesCount++;
    }
    if (dayResult.anomalies.length > 0) {
      totalAnomaliesCount += dayResult.anomalies.length;
    }
  }

  // Summary Metrics
  const summary = {
    daysWorked,
    totalWorkedMinutes,
    totalWorkedHoursStr: formatMinutesToHours(totalWorkedMinutes),
    averageDailyHoursStr: daysWorked ? formatMinutesToHours(Math.round(totalWorkedMinutes / daysWorked)) : '00h00',
    presenceRate: Math.min(100, Math.round((daysWorked / Math.max(1, elapsedWorkingDaysCount)) * 100)),
    totalDelaysCount,
    totalDelayMinutes,
    totalDelayHoursStr: formatMinutesToHours(totalDelayMinutes),
    totalAbsencesCount,
    totalAnomaliesCount,
    totalDaysInRange: days.length,
    elapsedWorkingDaysCount,
    standardStartTime: options.standardStartTime || '08:00'
  };

  return {
    period: {
      startDate: startDateStr,
      endDate: endDateStr,
      startDateFR: formatDateFR(startDateStr),
      endDateFR: formatDateFR(endDateStr)
    },
    summary,
    days
  };
}

module.exports = {
  calculateDayAttendance,
  processAttendanceRange,
  formatMinutesToHours,
  parseTimeToMinutes,
  formatDateFR,
  formatDateKey
};
