操作步骤
1. 先确认 origin 作为开源仓库

你当前本地仓库已经绑定 origin：

git remote -v


输出：

origin  git@github.com:jiangchengyu998/one-click-deployment.git (fetch)
origin  git@github.com:jiangchengyu998/one-click-deployment.git (push)


✅ 这个就是 opensource 仓库，不用改。

2. 添加 SaaS 仓库远程

执行：

git remote add saas git@github.com:jiangchengyu998/one-click-deployment-saas.git


确认一下：

git remote -v


输出应该是：

origin  git@github.com:jiangchengyu998/one-click-deployment.git (fetch)
origin  git@github.com:jiangchengyu998/one-click-deployment.git (push)
saas    git@github.com:jiangchengyu998/one-click-deployment-saas.git (fetch)
saas    git@github.com:jiangchengyu998/one-click-deployment-saas.git (push)

3. 推送 main 分支到两个仓库

你现在 main 分支的代码应该是开源功能：

git checkout main
git push origin main   # 推到开源仓库
git push saas main     # 同步一份到 SaaS 仓库

4. 创建 saas 分支（只在私有仓库）

在本地基于 main 创建 SaaS 分支：

git checkout -b saas main
# 修改 SaaS 专属逻辑，比如自动域名、Nginx 配置等
git commit -am "feat: SaaS version with domain auto assignment"
git push saas saas     # 只推到私有 SaaS 仓库


这样 GitHub 上的两个仓库情况就是：

one-click-deployment (public) → 只有 main 分支

one-click-deployment-saas (private) → 有 main 和 saas 分支

5. 后续开发流程

开发开源功能：在 main 分支改 → 推到两个仓库

git checkout main
git commit -am "fix: improve deployment logs"
git push origin main
git push saas main


开发 SaaS 功能：在 saas 分支改 → 只推到私有仓库

git checkout saas
git commit -am "feat: add nginx reload automation"
git push saas saas


保持同步（main → saas）

git checkout saas
git merge main
git push saas saas


⚡这样你就能保证：

开源仓库永远只有干净的 main

SaaS 仓库有完整逻辑（main + saas）