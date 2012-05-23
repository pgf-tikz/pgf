\begin{luatable}{<%=file_doc.shortname:match('(.*)%..-%.lua')..'.'%>}{<%=tab.name:gsub('_', '\\_')%>}
  <%if type(tab.field) == "table" and #tab.field > 0 then%>
  \emph{Fields:}
  \begin{description}
  <%for p = 1, #tab.field do%> \item[|<%=tab.field[p]:gsub('_', '\\_')%>|] <%=tab.field[tab.field[p]] or ""%> <%end%>
  \end{description}
  <%end%>
  <%=tab.description%>
\end{luatable}
