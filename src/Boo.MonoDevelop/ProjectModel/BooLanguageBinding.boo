namespace Boo.MonoDevelop.ProjectModel

import MonoDevelop.Core
import MonoDevelop.Projects
import System.Xml

import Boo.Ide
import Boo.MonoDevelop.Util

class BooLanguageBinding(BooIdeLanguageBinding, IDotNetLanguageBinding):
	
	ProjectStockIcon:
		get: return "md-boo-project"
	
	SingleLineCommentTag:
		get: return "#"
		
	BlockCommentStartTag:
		get: return "/*"
		
	BlockCommentEndTag:
		get: return "*/"
		
	Refactorer:
		get: return null
		
	Parser:
		get: return null
		
	Language:
		get: return "Boo"
		
	static def IsBooFile(fileName as string):
		return fileName.ToLower().EndsWith(".boo")
	
	def IsSourceCodeFile(fileName as FilePath):
		return IsBooFile(fileName)
		
	def IsSourceCodeFile(fileName as string):
		return IsBooFile(fileName)
		
	def GetFileName(baseName as FilePath):
		return baseName + ".boo"
		
	def GetFileName(baseName as string):
		return baseName + ".boo"
		
	def GetCodeDomProvider():
		return Boo.Lang.CodeDom.BooCodeProvider()
		
	def CreateProjectParameters(projectOptions as XmlElement):
		return BooProjectParameters()
		
	def CreateCompilationParameters(projectOptions as XmlElement):
		return BooCompilationParameters()
		
	def GetSupportedClrVersions():
		return (ClrVersion.Net_1_1, ClrVersion.Net_2_0, ClrVersion.Clr_2_1, ClrVersion.Net_4_0)
		
	def Compile(items as ProjectItemCollection,
				config as DotNetProjectConfiguration,
				selector as ConfigurationSelector,
				progressMonitor as IProgressMonitor):
		return BooCompiler(config, selector, items, progressMonitor).Run()
		
	override def CreateProjectIndex():
		return ProjectIndex()

		
	
	