export interface StateData {
  abbr: string
  name: string
  severity: number
  category: string
  deathPenalty: string
  murderRate: number
  gunDeathRate: number
  trafficFatalityRate: number
  population: number
  incarcerationRate: number
  notes: string
  center: {
    lat: number
    lng: number
    zoom: number
  }
}

export const US_AVERAGES = {
  murder: 7.2,
  gun: 14.8,
  traffic: 12.3,
  incarceration: 639
}

export const STATES_DATA: Record<string, StateData> = {
  TX: {
    abbr: 'TX',
    name: 'Texas',
    severity: 100,
    category: 'Very Severe',
    deathPenalty: 'Active (National leader in executions)',
    murderRate: 8.2,
    gunDeathRate: 15.6,
    trafficFatalityRate: 13.8,
    population: 30029572,
    incarcerationRate: 832,
    notes: 'Leads nation in executions since 1976. Active death penalty with regular executions.',
    center: { lat: 31.9686, lng: -99.9018, zoom: 5.5 }
  },
  CA: {
    abbr: 'CA',
    name: 'California',
    severity: 38,
    category: 'Lenient',
    deathPenalty: 'Moratorium (2019)',
    murderRate: 5.7,
    gunDeathRate: 8.5,
    trafficFatalityRate: 10.2,
    population: 39538223,
    incarcerationRate: 549,
    notes: 'Governor moratorium on death penalty. Focus on criminal justice reform and rehabilitation.',
    center: { lat: 36.7783, lng: -119.4179, zoom: 5.5 }
  },
  NY: {
    abbr: 'NY',
    name: 'New York',
    severity: 35,
    category: 'Lenient',
    deathPenalty: 'Abolished (2007)',
    murderRate: 4.7,
    gunDeathRate: 5.4,
    trafficFatalityRate: 8.3,
    population: 20201249,
    incarcerationRate: 376,
    notes: 'Abolished death penalty in 2007. Progressive criminal justice reforms.',
    center: { lat: 42.1657, lng: -74.9481, zoom: 6 }
  },
  FL: {
    abbr: 'FL',
    name: 'Florida',
    severity: 100,
    category: 'Very Severe',
    deathPenalty: 'Active',
    murderRate: 6.8,
    gunDeathRate: 14.2,
    trafficFatalityRate: 15.1,
    population: 21538187,
    incarcerationRate: 853,
    notes: 'Active death penalty with frequent use. Strict sentencing laws.',
    center: { lat: 27.6648, lng: -81.5158, zoom: 6 }
  },
  HI: {
    abbr: 'HI',
    name: 'Hawaii',
    severity: 20,
    category: 'Very Lenient',
    deathPenalty: 'Abolished (1957)',
    murderRate: 2.8,
    gunDeathRate: 4.8,
    trafficFatalityRate: 8.9,
    population: 1455271,
    incarcerationRate: 478,
    notes: 'Most progressive state. Abolished death penalty in 1957. Lowest crime rates.',
    center: { lat: 19.8968, lng: -155.5828, zoom: 6.5 }
  },
  // Add more states as needed
  // For now, adding a few more key states
  LA: {
    abbr: 'LA',
    name: 'Louisiana',
    severity: 95,
    category: 'Very Severe',
    deathPenalty: 'Active',
    murderRate: 15.8,
    gunDeathRate: 26.3,
    trafficFatalityRate: 18.2,
    population: 4657757,
    incarcerationRate: 1090,
    notes: 'Highest incarceration rate in nation. Active death penalty.',
    center: { lat: 30.9843, lng: -91.9623, zoom: 6.5 }
  },
  VT: {
    abbr: 'VT',
    name: 'Vermont',
    severity: 22,
    category: 'Very Lenient',
    deathPenalty: 'Abolished (1964)',
    murderRate: 2.2,
    gunDeathRate: 11.6,
    trafficFatalityRate: 9.8,
    population: 643077,
    incarcerationRate: 320,
    notes: 'Lowest incarceration rate in nation. Progressive rehabilitation focus.',
    center: { lat: 44.5588, lng: -72.5778, zoom: 7 }
  },
  MA: {
    abbr: 'MA',
    name: 'Massachusetts',
    severity: 28,
    category: 'Lenient',
    deathPenalty: 'Abolished (1984)',
    murderRate: 3.1,
    gunDeathRate: 3.7,
    trafficFatalityRate: 5.8,
    population: 7029917,
    incarcerationRate: 340,
    notes: 'Lowest gun death rate. Strong rehabilitation programs.',
    center: { lat: 42.4072, lng: -71.3824, zoom: 7 }
  },
  WA: {
    abbr: 'WA',
    name: 'Washington',
    severity: 35,
    category: 'Lenient',
    deathPenalty: 'Abolished (2018)',
    murderRate: 4.3,
    gunDeathRate: 10.9,
    trafficFatalityRate: 7.2,
    population: 7705281,
    incarcerationRate: 467,
    notes: 'Recently abolished death penalty. Focus on alternatives to incarceration.',
    center: { lat: 47.7511, lng: -120.7401, zoom: 6.5 }
  },
  IL: {
    abbr: 'IL',
    name: 'Illinois',
    severity: 38,
    category: 'Lenient',
    deathPenalty: 'Abolished (2011)',
    murderRate: 9.1,
    gunDeathRate: 14.1,
    trafficFatalityRate: 8.7,
    population: 12812508,
    incarcerationRate: 539,
    notes: 'Abolished death penalty in 2011 after wrongful conviction concerns.',
    center: { lat: 40.6331, lng: -89.3985, zoom: 6.5 }
  }
}

// You can add the remaining 40 states following the same pattern
// For the demo, I'll show how to dynamically handle missing states

export function getStateData(abbr: string): StateData | null {
  return STATES_DATA[abbr] || null
}

export function getAllStates(): StateData[] {
  return Object.values(STATES_DATA)
}

export function getStatesByCategory(category: string): StateData[] {
  return getAllStates().filter(s => s.category === category)
}

