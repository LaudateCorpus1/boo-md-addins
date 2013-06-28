namespace UnityScript.MonoDevelop.ProjectModel

import MonoDevelop.Core
import MonoDevelop.Projects
import System.Xml

import UnityScript.MonoDevelop

import Boo.MonoDevelop.Util

class UnityScriptLanguageBinding(BooIdeLanguageBinding, IDotNetLanguageBinding):
	
	ProjectStockIcon:
		get: return "md-unityscript-project"
	
	SingleLineCommentTag:
		get: return "//"
		
	BlockCommentStartTag:
		get: return "/*"
		
	BlockCommentEndTag:
		get: return "*/"
		
	Refactorer:
		get: return null
		
	Parser:
		get: return null
		
	Language:
		get: return "UnityScript"
		
	def IsSourceCodeFile(fileName as string):
		return IsUnityScriptFile(fileName)
		
	def IsSourceCodeFile(fileName as FilePath):
		return IsUnityScriptFile(fileName)
		
	def GetFileName(baseName as string):
		return baseName + ".js"
		
	def GetFileName(baseName as FilePath):
		return baseName + ".js"
		
	def GetCodeDomProvider():
		return UnityScriptCodeDomProvider()
		
	def CreateProjectParameters(projectOptions as XmlElement):
		return UnityScriptProjectParameters()
		
	def CreateCompilationParameters(projectOptions as XmlElement):
		return UnityScriptCompilationParameters()
		
	def GetSupportedClrVersions():
		return (ClrVersion.Net_1_1, ClrVersion.Net_2_0, ClrVersion.Clr_2_1, ClrVersion.Net_4_0)
		
	def Compile(items as ProjectItemCollection,
				config as DotNetProjectConfiguration,
				selector as ConfigurationSelector,
				progressMonitor as IProgressMonitor):
		return UnityScriptCompiler(config, selector, items, progressMonitor).Run()
		
	override def CreateProjectIndex():
		return UnityScript.Ide.UnityScriptProjectIndexFactory.CreateUnityScriptProjectIndex()
