<%
if module_doc then
	from = "modules/"..module_doc.name
elseif file_doc then
	from = "files/.."..file_doc.name
else
	from = ""
end
%><%=func.private and "local " or ""%>\begin{luacommand}{{<%=func.name%>}(<%for i, paramname in ipairs(func.param) do%><%if i ~= 1 then%><%=","%><%end%><%="\\meta{"..paramname.."}"%><%end%>)}
<%=func.description or ""%>
<%if type(func.param) == "table" and #func.param > 0 then%><%hasParam=nil%><%for p=1, #func.param do if func.param[func.param[p]] then hasParam=1 end end%><%if hasParam then%>
Parameters:
\begin{itemize}
	<%for p = 1, #func.param do%><%if func.param[func.param[p]] then%>\item[] \meta{<%=func.param[p]%>} \subitem <%=func.param[func.param[p]] or ""%><%end%><%end%>
\end{itemize}
<%end%><%end%>
<%if type(func.ret) == "string" then%>
Return value:
\begin{itemize} \item[] <%=func.ret%> \end{itemize}
<%elseif type(func.ret) == "table" then%>
Return values:
\begin{enumerate}
	<%for _, ret in ipairs(func.ret) do%>
	\item <%= ret %>
	<%end%>
\end{enumerate}
<%end%>
<%if type(func.see) == "string" then %>
See also:
	|<%=func.see%>|
<%elseif type(func.see) == "table" and #func.see > 0 then %>
See also:
\begin{itemize}
	<%for i = 1, #func.see do%>\item[] |<%=func.see[i]%>|<%end%>
\end{itemize}
<%end%>
\end{luacommand}