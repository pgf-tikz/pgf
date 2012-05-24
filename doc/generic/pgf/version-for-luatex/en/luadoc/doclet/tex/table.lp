\begin{luatable}{<%=file_doc.shortname:match('(.*)%..-%.lua')..'.'%>}{<%=tab.name:gsub('_', '\\_')%>}
  <%=tab.description%>
  <%if type(tab.field) == "table" and #tab.field > 0 then%>
  \emph{Fields:}
  \begin{itemize}
  <%for p = 1, #tab.field do%> \item \texttt{<%=tab.field[p]:gsub('_', '\\_')%>}\kern1em <%=tab.field[tab.field[p]] or ""%> <%end%>
  \end{itemize}
  <%end%>
\end{luatable}
