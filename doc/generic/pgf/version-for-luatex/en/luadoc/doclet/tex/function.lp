<%
if module_doc then
	from = "modules/"..module_doc.name
elseif file_doc then
	from = "files/.."..file_doc.name
else
	from = ""
end
%><%=func.private and "local " or ""%>\begin{luacommand}{{<%=func.name%>}(<%for i, paramname in ipairs(func.param) do%><%if i ~= 1 then%><%=","%><%end%><%="\\meta{"..paramname:gsub('_', '\\_').."}"%><%end%>)}
<%=func.description or ""%>
<%if type(func.param) == "table" and #func.param > 0 then%><%hasParam=nil%><%for p=1, #func.param do if func.param[func.param[p]] then hasParam=1 end end%><%if hasParam then%>
\emph{Parameters:}
\begin{parameterdescription}
	<%for p = 1, #func.param do%><%if func.param[func.param[p]] then%><%local param_name = func.param[p] or ''; param_name = param_name:gsub('_', '\\_')%><%local param_desc = func.param[func.param[p]] or ''; param_desc = param_desc:gsub('  ', ' ')%>\item[\meta{<%=param_name%>}] <%=param_desc%><%end%><%end%>
\end{parameterdescription}
<%end%><%end%>
<%if type(func.ret) == "string" then%>
\emph{Return value:}
\begin{parameterdescription} 
  \item[] <%=func.ret%>
\end{parameterdescription}
<%elseif type(func.ret) == "table" then%>
Return values:
\begin{parameterdescription}
	<%for _, ret in ipairs(func.ret) do%>
	\item <%= ret %>
	<%end%>
\end{parameterdescription}
<%end%>
<%if type(func.see) == "string" then %>
\emph{See also:}
	|<%=func.see%>|
<%elseif type(func.see) == "table" and #func.see > 0 then %>
\emph{See also:}
\begin{itemize}
	<%for i = 1, #func.see do%>\item[] |<%=func.see[i]%>|<%end%>
\end{itemize}
<%end%>
\end{luacommand}
