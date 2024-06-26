SELECT * 
FROM dbo.CovidDeaths
WHERE continent is not null
ORDER BY 3,4

UPDATE dbo.CovidVaccinations
SET new_vaccinations = NULL
WHERE new_vaccinations = ' ';

SELECT * 
FROM dbo.CovidVaccinations
ORDER BY 3,4

-- DATA USED
SELECT location, date, total_cases, new_cases, total_deaths, population
FROM dbo.CovidDeaths
ORDER BY 1,2

--lOOKING AT THE TOTAL CASES VS TOTAL DEATHS
UPDATE dbo.CovidDeaths
SET total_deaths = NULL
WHERE total_deaths = ' ';
--SHOWS THE LIKELIHOOD OF DYING IF YOU CONTRACT THE VIRUS IN YOUR COUNTRY
SELECT location, date, total_deaths, total_cases, (CONVERT(float, total_deaths) / NULLIF(CONVERT(float, total_cases),0))*100 AS DeathPercentage
FROM dbo.CovidDeaths
WHERE location like '%states%'
ORDER BY 1,2

-- LOOKING AT THE TOTAL CASES VS POPULATION
-- SHOWS WHAT PERCETAGE OF POPULATION GOT THE VIRUS
SELECT location, date, population, total_deaths, total_cases, (CONVERT(float, total_cases) / NULLIF(CONVERT(float, population),0))*100 AS CasePercent
FROM dbo.CovidDeaths
WHERE location like '%states%'
ORDER BY 1,2


--LOOKING AT COUNTRIES WITH THE HIIGHEST INFECTION RATE COMPARED TO POPULATION
SELECT location, population, MAX(total_cases) AS HighestInfectionCount, MAX((CONVERT(float, total_cases)) / NULLIF(CONVERT(float, population),0))*100 AS PercentofPopulationInfected
FROM dbo.CovidDeaths
--WHERE location like '%states%'
GROUP BY location, population
ORDER BY PercentofPopulationInfected DESC

--SHOWING COUNTRIES WITH HIGHEST DEATH COUNT PER POPULATION
SELECT location, MAX(CAST(total_deaths as INT)) AS TotalDeathCount
FROM dbo.CovidDeaths
WHERE continent is not null
GROUP BY location
ORDER BY TotalDeathCount DESC

--SHOWING CONTINENTS WITH HIGHEST DEATH COUNT PER POPULATION
SELECT continent, MAX(CAST(total_deaths as INT)) AS TotalDeathCount
FROM dbo.CovidDeaths
WHERE continent is not null
GROUP BY continent
ORDER BY TotalDeathCount DESC

-- GLOBAL NUMBERS

UPDATE dbo.CovidDeaths
SET new_deaths = NULL
WHERE new_deaths = ' ';

SELECT 
    date, 
    SUM(CAST(new_cases AS int)) AS total_cases, 
    SUM(CAST(new_deaths AS int)) AS total_deaths, 
    CASE 
        WHEN SUM(CAST(new_cases AS int)) = 0 THEN 0  -- Handle division by zero scenario
        ELSE SUM(CAST(new_deaths AS int)) * 100.0 / SUM(CAST(new_cases AS int))
    END AS DeathPercentage
FROM 
    dbo.CovidDeaths
WHERE 
    continent IS NOT NULL
GROUP BY 
    date
ORDER BY 
    date;

--JOINING TABLES, LOOKING AT TOTAL POPULATION VS VACCINATIONS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(INT, vac.new_vaccinations)) OVER (Partition by dea.location ORDER BY dea.location,
dea.date) AS RollingPeopleVaccinated
, (RollingPeopleVaccinated/population)*100
FROM dbo.CovidDeaths  dea
JOIN dbo.CovidVaccinations vac
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null
ORDER BY 2,3


--USE CTE

WITH PopvsVac (Continent, Location, Date, Population, New_Vaccionations, RollingPeopleVaccinated)
as
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(INT, vac.new_vaccinations)) OVER (Partition by dea.location ORDER BY dea.location,
dea.date) AS RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
FROM dbo.CovidDeaths  dea
JOIN dbo.CovidVaccinations vac
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null
--ORDER BY 2,3
)
SELECT *, (RollingPeopleVaccinated/Population)*100
FROM PopvsVac


--TEMP TABLE
DROP TABLE IF exists #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

INSERT INTO #PercentPopulationVaccinated
SELECT 
    dea.continent, 
    dea.location, 
    dea.date, 
    dea.population, 
    vac.new_vaccinations,
    SUM(CAST(vac.new_vaccinations as int)) OVER (PARTITION BY dea.location ORDER BY dea.date) AS RollingPeopleVaccinated
FROM 
    dbo.CovidDeaths dea
JOIN 
    dbo.CovidVaccinations vac ON dea.location = vac.location
                              AND dea.date = vac.date
WHERE 
    dea.continent IS NOT NULL

SELECT 
    Continent, 
    Location, 
    Date, 
    Population, 
    New_vaccinations, 
    RollingPeopleVaccinated,
    (RollingPeopleVaccinated / Population)*100 AS VaccinationPercentage
FROM 
    #PercentPopulationVaccinated


-- CREATING VIEW 
CREATE VIEW PercentPopulationVaccinated AS

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(INT, vac.new_vaccinations)) OVER (Partition by dea.location ORDER BY dea.location,
dea.date) AS RollingPeopleVaccinated

FROM dbo.CovidDeaths  dea
JOIN dbo.CovidVaccinations vac
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null
