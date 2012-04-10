-- Copyright 2012 by Till Tantau
--
-- This file may be distributed an/or modified
--
-- 1. under the LaTeX Project Public License and/or
-- 2. under the GNU Public License
--
-- See the file doc/generic/pgf/licenses/LICENSE for more information

-- @release $Header$

pgf.module("pgf.graphdrawing")

event_handling = {}


--- Store for each begin/end event the index of
-- its corresponding end/begin event
--
-- @param events An event list

function event_handling.prepare_event_list(events)

  local stack = {}

  for i=1,#events do
    if events[i].kind == "begin" then
      stack[#stack + 1] = i
    elseif events[i].kind == "end" then
      local tos = stack[#stack]
      stack[#stack] = nil -- pop

      events[tos].end_index = i
      events[i].begin_index = tos
    end
  end
end


--- Compute the number of events in a group of a certain kind
--
-- @param events The event list
-- @param kind The kind we are looking for
-- @param begin_index The index of a begin event or nil, if the whole event list is meant

function event_handling.number_of_events_of_kind(events,kind,begin_index)
  local end_index = begin_index and events[begin_index].end_index or #events+1
  local begin_index = begin_index or 0
  
  local count = 0
  for i=begin_index+1,end_index-1 do
    if events[i].kind == kind then
      count = count + 1
    end
  end

  return count
end



--- Compute the number of events in a group of a certain kind that are
-- not inside a group themselves
--
-- @param events The event list
-- @param kind The kind we are looking for
-- @param begin_index The index of a begin event or nil, if the whole event list is meant

function event_handling.number_of_events_of_kind_outside_groups(events,kind,begin_index)
  local end_index = begin_index and events[begin_index].end_index or #events
  local begin_index = begin_index or 1
  
  local count = 0
  local i = begin_index
  while i <= end_index do
    if events[i].kind == "begin" then
      count = events[i].end_index -- warp
    elseif events[i].kind == kind then
      count = count + 1
    end
    i = i + 1
  end

  return count
end