--Covid-19 Data Cleaning Project
---Note that data was downloaded on the 15th May 2023

---Change numeric data from varchar to int & float data types
--alter table CovidDeaths
--alter column _deaths float,total_cases, total_deaths, new_cases, new_deaths

---Total Cases VS Total Deaths in Canada ---shows likelyhood of dying if convid was contracted in Canada
--(NullIF was used to avoid the "divide by zero" error as the data had 0 for some case dates.
select location,date,total_cases,total_deaths,total_deaths / NULLIF(total_cases,0)*100 as death_percentage
from.CovidDeaths
where location = 'Canada'
Order by death_percentage desc

--Total cases v population (What percentage of the population has gotten covid)**Note that the % is incremental
select location,date,population,total_cases, (total_cases / NULLIF(population,0))*100 as Pop_Covid_percentage
from.CovidDeaths
where location = 'Canada'
Order by total_cases desc

--Countries with highest infection rate compared to the population
select location,population, MAX(total_cases)as Total_Infected_Count, MAX(total_cases / NULLIF(population,0))*100 as Perc_Pop_Infected
from.CovidDeaths
Group by location, population
Order by Perc_Pop_Infected desc

--Countries with highest death count per population
--location data also captured the continents of the world + Income Strata and had to be excluded for this view
select location,population, MAX(total_deaths)as Total_death_Count, MAX(total_deaths / NULLIF(population,0))*100 as Perc_of_totalDeaths
from.CovidDeaths
where location NOT IN ('World','Europe', 'European Union', 'High income', 'Asia', 'North America', 'South America', 'Upper middle income', 'Lower middle income')
Group by location, population
Order by Total_death_Count desc

--Joining coviddeaths and covidvaccinations tables
--Total population vs Total Vaccinations
select d.continent, d.location, d.date, d.population, v.total_vaccinations
from .CovidDeaths d
join .CovidVaccinations v
on
d.location = v.location
---where d.continent IN ('World','Europe', 'European Union', 'High income', 'Asia', 'North America', 'Oceania', 'South America', 'Upper middle income', 'Lower middle income')
---Group by d.continent, d.location, d.population, d.date, v.total_vaccinations
--order by continent


--Joining coviddeaths and covidvaccinations tables
--Total population vs New Vaccinations
--Adding a rollling count (partion by & Windows function)
select d.continent, d.location, d.date, d.population, v.new_vaccinations,
sum(cast(v.new_vaccinations as bigint)) over (partition by d.location order by d.location,d.date) as rolling_cnt_pple_vaci--(partion by adds a rolling count.** the date partition helped create the rolling effect.) *Also note that new vacina was casted as bigint. that was to avoid the arith metic overflow error)
from .CovidDeaths d
join .CovidVaccinations v
on
d.location = v.location and d.date = v.date
where d.continent <> '' -- ("<> ''" means Not equal to: used bcos I didn't want to show blank rows in the result)
order by 2,3

--Using CTE to get the % of the rolling count of people who were vaccinated
-- Note that CTE was used because u can't use a calculated column "rolling_cnt_pple_vaci" as above to perform additional calculations of / and * to get the %

with popvsvac (continent, location, date, population, new_vaccination, rolling_cnt_pple_vaci) --(popvssec is population vs vaccinatted
as 
(
select d.continent, d.location, d.date, d.population, v.new_vaccinations,
sum(cast(v.new_vaccinations as bigint)) over (partition by d.location order by d.location,d.date) as rolling_cnt_pple_vaci--(partion by adds a rolling count.** the date partition helped create the rolling effect.) *Also note that new vacina was casted as bigint. that was to avoid the arith metic overflow error)
from .CovidDeaths d
join .CovidVaccinations v
on
d.location = v.location and d.date = v.date
where d.continent <> '' -- ("<> ''" means Not equal to: used bcos I didn't want to show blank rows in the result)
---order by 2,3 ---(order by cannot be in this cte)
)
select *, (rolling_cnt_pple_vaci/population)*100 as perc_rolling_cnt_pple_vaci
from popvsvac
--cte ends here (you have to run all the above at once)

---Create a TEMP TABLE (same result as cte)
drop table if exists #popvsvac
create table #popvsvac
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
new_vaccinations numeric,
rolling_cnt_pple_vaci numeric
)
insert into #popvsvac

select d.continent, d.location, d.date, d.population, v.new_vaccinations,
sum(cast(v.new_vaccinations as bigint)) over (partition by d.location order by d.location,d.date) as rolling_cnt_pple_vaci--(partion by adds a rolling count.** the date partition helped create the rolling effect.) *Also note that new vacina was casted as bigint. that was to avoid the arith metic overflow error)
from .CovidDeaths d
join .CovidVaccinations v
on
d.location = v.location and d.date = v.date
where d.continent <> '' -- ("<> ''" means Not equal to: used bcos I didn't want to show blank rows in the result)
---order by 2,3 ---(order by cannot be in this cte)

select *, (rolling_cnt_pple_vaci/population)*100 as perc_rolling_cnt_pple_vaci
from #popvsvac

---Creating a View
create view popvsvac as 
select d.continent, d.location, d.date, d.population, v.new_vaccinations,
sum(cast(v.new_vaccinations as bigint)) over (partition by d.location order by d.location,d.date) as rolling_cnt_pple_vaci--(partion by adds a rolling count.** the date partition helped create the rolling effect.) *Also note that new vacina was casted as bigint. that was to avoid the arith metic overflow error)
from .CovidDeaths d
join .CovidVaccinations v
on
d.location = v.location and d.date = v.date
where d.continent <> '' -- ("<> ''" means Not equal to: used bcos I didn't want to show blank rows in the result)
---order by 2,3 ---(order by cannot be in this cte)

---Querying a view (Note that popvssac is now like a table (view)
select *
from popvsvac